--!strict
--!optimize 2
--@version dialogsystem-6.1.3
--@creator Camille
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

-- this is a port of the v5.5 dialog co script to v6
-- i kept the structure of the dialog and the functions as-is because
-- changing it all to use v6 stuff would take too long

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local DialogSystem = {
	CanQueue = true,
	RunOnStart = false,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

type TextSequence = {
	Text: string,
	Info: { [string]: any },
	Effects: { [string]: { any } },
	TypeSound: Sound?,
}

function DialogSystem.Run(scope: _T.Scope, utility: _T.Utility)
	local Config = utility.Config
	local roundColor = utility.Functions.roundColor

	local objectConfig = scope.instance
	if not objectConfig or not objectConfig.Parent then
		return
	end

	local dialogFolder = objectConfig.Parent
	if not dialogFolder then
		return
	end

	local dialogParts = dialogFolder:FindFirstChild("Parts")
	if not dialogParts then
		return
	end

	-- important variables
	local player = Players.LocalPlayer
	local playerMouse = player:GetMouse()
	local Typewriter = require(ReplicatedStorage:WaitForChild("DialogModuleInstance").Value)

	local dialogUI = player.PlayerGui:WaitForChild("Dialog")
	local textFrame = dialogUI:WaitForChild("textFrame")

	-- setup text frame
	textFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	textFrame.Position = UDim2.fromScale(0.5, 0.855)

	-- other variables
	local dialogDebounce = false

	-- button cache (for button activating)
	local buttonScript = scope.repository["Interactables/Button"]
	if typeof(buttonScript) ~= "table" then
		return -- Button script not used here
	end

	local buttonCommunicator = buttonScript.Communicator
	local buttonRequest = scope:getCommunicator("request", buttonCommunicator.KEY)
	local buttonCache = buttonRequest:request(buttonCommunicator.AWAIT_CACHE)

	local function activateButtonFromColor(color: Color3)
		for _, button in buttonCache.Buttons do
			if button.Color == color then
				button.Pressed.Value = true
			end
		end
	end
	
	local function activateButtonFromTag(tag: string)
		for _, button in buttonCache.Buttons do
			if not button.Button or not button.Button.Parent then
				continue
			end
			
			if button.Button.Parent:HasTag(tag) then
				button.Pressed.Value = true
			end
		end
	end

	local function evaluateToucher(part: BasePart, toucher: BasePart): boolean
		local parent = toucher.Parent
		if not parent then
			return false
		end

		local ancestor = parent.Parent
		local playerTouched = Players:GetPlayerFromCharacter(toucher.Parent)

		local partAttributes = part:GetAttributes()
		local colorSpecificCheck = not (
			partAttributes.ColorSpecificCheck and (roundColor(toucher.Color) ~= roundColor(part.Color))
		)

		local playerCheck = partAttributes.PlayerTouchActivated and playerTouched == player
		local pushboxCheck = partAttributes.PushboxTouchActivated
			and utility.ClientObjects.isPushbox(toucher)
			and colorSpecificCheck

		return (playerCheck or pushboxCheck)
	end

	for _, part in dialogParts:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		local dialogConfiguration = part:FindFirstChild("__DIALOG__")
		if not dialogConfiguration then
			continue
		end

		task.spawn(function()
			local sequences = {}
			for _, dialogSequence in dialogConfiguration:GetChildren() do
				if not dialogSequence:IsA("Configuration") then
					continue
				end

				local sequenceOrder = tonumber(string.match(dialogSequence.Name, "%d+"))
				if not sequenceOrder then
					continue
				end
				
				local dialogAttributes = dialogSequence:GetAttributes()
				local textSequences: { TextSequence } = {}
				for _, textSequence in dialogSequence:GetChildren() do
					if not textSequence:IsA("StringValue") then
						continue
					end

					local textSequenceOrder = tonumber(string.match(textSequence.Name, "%d+"))
					if not textSequenceOrder then
						continue
					end

					local text = textSequence.Value
					local textAttributes = textSequence:GetAttributes()

					local thisTextSequence: TextSequence = {
						Text = text,
						Info = textAttributes,
						Effects = {},
						TypeSound = textSequence:FindFirstChild("TypeSFX") :: Sound,
					}

					textSequences[textSequenceOrder] = thisTextSequence

					if textSequenceOrder > 1 then
						textSequences[textSequenceOrder].Text = ` {text}`
					end

					local effects = textSequence:FindFirstChild("Effects")
					if effects then
						for _, effectValue in effects:GetChildren() do
							if effectValue:IsA("BoolValue") then
								thisTextSequence.Effects[effectValue.Name] =
									{ effectValue.Value, effectValue:GetAttributes() }
							end
						end
					end
				end

				sequences[sequenceOrder] = function()
					local function runDialog()
						Typewriter:Write({
							Texts = textSequences,
							TimeAfter = dialogAttributes.RemoveAfter,
							WaitUntilFade = dialogAttributes.AwaitTextFade,
							ClearInterval = dialogAttributes.ClearInterval,
							ManualAdvance = dialogAttributes.ManualAdvance,
						})
					end

					if typeof(dialogAttributes.ActivateButtonBeforeDialog) == "Color3" then
						activateButtonFromColor(roundColor(dialogAttributes.ActivateButtonBeforeDialog))
					end
					
					if typeof(dialogAttributes.ActivateButtonTagBeforeDialog) == "string" then
						activateButtonFromTag(dialogAttributes.ActivateButtonTagBeforeDialog)
					end

					if dialogAttributes.AwaitFinish then
						runDialog()
					else
						task.spawn(runDialog)
					end
					
					local delayAfterFinish = if dialogAttributes.ManualAdvance
						then 0
						else dialogAttributes.DelayAfterFinish
					task.wait(delayAfterFinish)

					if typeof(dialogAttributes.ActivateButton) == "Color3" then
						activateButtonFromColor(roundColor(dialogAttributes.ActivateButton))
					end
					
					if typeof(dialogAttributes.ActivateButtonTag) == "string" then
						activateButtonFromTag(dialogAttributes.ActivateButtonTag)
					end
				end
			end

			local function start()
				if part:GetAttribute("Activated") == false then
					return
				end

				local uses = part:GetAttribute("Uses")
				if typeof(uses) == "number" and uses <= 0 then
					return
				end
				if dialogDebounce then
					return
				end
				dialogDebounce = true

				if typeof(uses) == "number" then
					uses -= 1
					part:SetAttribute("Uses", uses)
				end

				for sequenceOrder, sequenceFunction in sequences do
					sequenceFunction()
				end

				if typeof(uses) == "number" and uses <= 0 then
					part:Destroy()
				end

				task.delay(0.1, function()
					dialogDebounce = false
				end)
			end

			local partAttributes = part:GetAttributes()

			if partAttributes.PlayerTouchActivated or partAttributes.PushboxTouchActivated then
				part.Touched:Connect(function(toucher: BasePart)
					if not evaluateToucher(part, toucher) then
						return
					end

					start()
				end)
			end

			if partAttributes.ClickActivated then
				local clickDetector = Instance.new("ClickDetector", part)
				local clickDistance = partAttributes.ClickDistance or 32

				clickDetector.MaxActivationDistance = clickDistance
				clickDetector.MouseClick:Connect(function(clickPlayer: Player)
					if clickPlayer ~= player then
						return
					end

					clickDetector.MaxActivationDistance = 0
					start()
					clickDetector.MaxActivationDistance = clickDistance
				end)
			end

			if partAttributes.ProximityActivated then
				local proximityPrompt = Instance.new("ProximityPrompt", part)
				local clickDistance = partAttributes.ClickDistance or 32

				proximityPrompt.ActionText = partAttributes.ActionText or "Dialog"
				proximityPrompt.RequiresLineOfSight = false
				proximityPrompt.MaxActivationDistance = clickDistance

				proximityPrompt.Triggered:Connect(function(triggerPlayer: Player)
					if triggerPlayer ~= player then
						return
					end

					proximityPrompt.MaxActivationDistance = 0
					start()
					proximityPrompt.MaxActivationDistance = clickDistance
				end)
			end

			--> Sequencer Cache Support
			local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
			cache[part] = start
			scope:add(function()
				cache[part] = nil
				cache = nil :: any
			end)
		end)
	end
end

return DialogSystem
