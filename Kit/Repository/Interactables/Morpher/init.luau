--!strict
--!optimize 2
--@version morpher-6.1.3
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local Morpher = {
	CanQueue = true,
	RunOnStart = false,
}

local BUTTON_CONFIG_TEMPLATE
local TOUCH_CONFIGURATION
local TWEEN_CONFIGURATION
function Morpher.Init(utility: _T.Utility)
	local Config = utility.Config
	BUTTON_CONFIG_TEMPLATE = {
		Timer = 0,
		TimerText = "{T}",
		TimerDecimalPlaces = 1,
		CarryObjects = true,
	}
	TOUCH_CONFIGURATION = Config.TOUCH_CONFIG
	TWEEN_CONFIGURATION = Config.TWEEN_CONFIG
end

type MorpherButton = {
	morpherID: string,

	button: Model,
	buttonParts: { BasePart },
	newMorphParts: { BasePart },

	buttonConfiguration: typeof(BUTTON_CONFIG_TEMPLATE),
	touchConfiguration: typeof(TOUCH_CONFIGURATION),

	sounds: { [string]: Sound },

	lastTouchedButtonPart: BasePart?,
	timerData: MorpherTimer?,

	morpher: Instance,
	morphPart: BasePart,
	defaultMorph: BasePart,
	cloneMorphs: { BasePart },
	durationGui: BillboardGui,

	MoveTween: typeof(TWEEN_CONFIGURATION),
	ReturnTween: typeof(TWEEN_CONFIGURATION),
	activate: () -> (),
}

type MorpherTimer = {
	startTime: number,
	durationBillboard: BillboardGui,
	timerLabel: TextLabel,
	lastFullSecond: number?,
}

type MorpherLerp = {
	morpherID: string,
	startTime: number,
	duration: number,
	tweenInfo: TweenInfo,
	parts: { MorpherLerpPart },
	carryObjects: boolean,
	morpherButton: MorpherButton,
}

type MorpherLerpPart = {
	part: BasePart,

	startCFrame: CFrame,
	endCFrame: CFrame,

	startColor: Color3,
	endColor: Color3,

	startSize: Vector3,
	endSize: Vector3,
}

type MorpherCache = {
	morpherButtons: { [string]: { MorpherButton } },
	morpherLerps: { [string]: { MorpherLerp } },
	currentMorpherButtons: { [string]: MorpherButton? },
	setupMorpherButton: (
		morpherButton: Model,
		morpherID: string,
		morpher: Instance,
		defaultMorph: BasePart,
		morphPart: BasePart,
		cloneMorphs: { BasePart },
		durationGui: BillboardGui,
		scope: _T.Scope
	) -> (),
}

local SequencerSupport = require(script.SequencerSupport)
local function handleMorpherCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {
		morpherButtons = {},
		morpherLerps = {},
		currentMorpherButtons = {},
	} :: MorpherCache
	local coUtil = utility.ClientObjects

	local function playPressSound(morpherButton: MorpherButton)
		local sound = morpherButton.sounds.press:Clone()
		sound.Parent = morpherButton.lastTouchedButtonPart
		sound:Play()
		task.delay(sound.TimeLength / sound.PlaybackSpeed, function()
			sound:Destroy()
		end)
	end

	local function getTweenInfo(morpherButton: MorpherButton, isReturn: boolean?): TweenInfo
		local tweenInfo = if isReturn then morpherButton.ReturnTween else morpherButton.MoveTween
		return TweenInfo.new(tweenInfo.Time, tweenInfo.Style, tweenInfo.Direction)
	end

	local function deactivateButton(morpherButton: MorpherButton)
		local tweenInfo = getTweenInfo(morpherButton, true)
		local tweenProperties = { Color = Color3.new() }
		for _, buttonPart in morpherButton.buttonParts do
			utility.Functions.tween(
				buttonPart,
				tweenInfo.Time,
				tweenProperties,
				tweenInfo.EasingStyle,
				tweenInfo.EasingDirection
			)
		end

		-- cancel timer if one is active
		if morpherButton.timerData then
			morpherButton.timerData.durationBillboard:Destroy()
			morpherButton.timerData = nil
		end

		table.clear(cache.morpherLerps[morpherButton.morpherID])
	end

	local function createLerpPart(part: BasePart, destination: BasePart): MorpherLerpPart
		return {
			part = part,

			startCFrame = part.CFrame,
			endCFrame = destination.CFrame,

			startColor = part.Color,
			endColor = destination.Color,

			startSize = part.Size,
			endSize = destination.Size,
		}
	end

	local function createLerp(
		morpherButton: MorpherButton,
		parts: { BasePart },
		destination: BasePart,
		tweenInfo: TweenInfo
	)
		local partTable = {}
		local morpherID = morpherButton.morpherID
		-- set up lerp parts
		for _, part in parts do
			table.insert(partTable, createLerpPart(part, destination))
		end

		-- only the latest main morph lerp matters, disconnect any other ones
		if #parts == 1 and parts[1] == morpherButton.morphPart then
			table.clear(cache.morpherLerps[morpherID])
		end

		local lerpTable: MorpherLerp = {
			morpherID = morpherID,
			startTime = os.clock(),
			duration = tweenInfo.Time,
			tweenInfo = tweenInfo,
			parts = partTable,
			carryObjects = morpherButton.buttonConfiguration.CarryObjects,
			morpherButton = morpherButton,
		}

		table.insert(cache.morpherLerps[morpherID], lerpTable)
	end

	local function resetMorphs(morpherButton: MorpherButton)
		local cloneMorphs = morpherButton.cloneMorphs
		local tweenInfo = getTweenInfo(morpherButton, true)
		createLerp(
			morpherButton,
			{ morpherButton.morphPart, table.unpack(cloneMorphs) },
			morpherButton.defaultMorph,
			tweenInfo
		)

		for _, cloneMorph in cloneMorphs do
			task.spawn(function()
				task.wait(morpherButton.ReturnTween.Time)
				cloneMorph:Destroy()
			end)
		end

		cache.currentMorpherButtons[morpherButton.morpherID] = nil
	end

	local function updateMorpherLerp(morpherLerp: MorpherLerp, deltaTime: number)
		debug.profilebegin("Morpher -> Update Lerp")

		local elapsed = math.clamp((os.clock() - morpherLerp.startTime) / morpherLerp.duration, 0, 1)
		local alpha =
			TweenService:GetValue(elapsed, morpherLerp.tweenInfo.EasingStyle, morpherLerp.tweenInfo.EasingDirection)

		local morpherButton = morpherLerp.morpherButton
		
		local function cleanup()
			if morpherButton.button and morpherLerp.carryObjects then
				for _, lerpPart in morpherLerp.parts do
					lerpPart.part.AssemblyLinearVelocity = Vector3.zero
					lerpPart.part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			
			local thisCache = cache.morpherLerps[morpherButton.morpherID]
			local tableIndex = table.find(thisCache, morpherLerp)
			if tableIndex then
				table.remove(thisCache, tableIndex)
			end
		end
		
		if not morpherButton.button then
			cleanup()
			debug.profileend()
			return
		end

		local partList = {}
		local cframeList = {}

		for _, lerpPart in morpherLerp.parts do
			local part = lerpPart.part

			local newSize = lerpPart.startSize:Lerp(lerpPart.endSize, alpha)
			part.Size = newSize

			if part.Anchored then
				local newCFrame = lerpPart.startCFrame:Lerp(lerpPart.endCFrame, alpha)
				table.insert(partList, part)
				table.insert(cframeList, newCFrame)

				if morpherLerp.carryObjects then
					local oldCFrame = part.CFrame
					local positionDifference = newCFrame.Position - oldCFrame.Position
					part.AssemblyLinearVelocity = positionDifference / deltaTime
					part.AssemblyAngularVelocity = Vector3.new(
						oldCFrame.Rotation:ToObjectSpace(newCFrame.Rotation):ToOrientation()
					) / deltaTime
				end
			end

			local newColor = lerpPart.startColor:Lerp(lerpPart.endColor, alpha)
			part.Color = newColor
		end

		debug.profilebegin("Morpher -> Update Lerp -> BulkMoveTo")
		Workspace:BulkMoveTo(partList, cframeList, Enum.BulkMoveMode.FireCFrameChanged)
		debug.profileend()
		
		if elapsed >= 1 then
			cleanup()
			debug.profileend()
			return
		end
		debug.profileend()
	end

	local function updateMorpherTimer(morpherButton: MorpherButton)
		debug.profilebegin("Morpher -> Update Timer")

		local timerData = morpherButton.timerData
		if not timerData then
			debug.profileend()
			return
		end

		local timePassed = os.clock() - timerData.startTime
		local timeRemaining = morpherButton.buttonConfiguration.Timer - timePassed

		-- deactivate if time is up
		if timeRemaining <= 0 then
			deactivateButton(morpherButton)
			resetMorphs(morpherButton)
			debug.profileend()
			return
		end

		-- update timer label
		local configuration = morpherButton.buttonConfiguration
		local timerText =
			coUtil.formatTimerText(configuration.TimerText, configuration.TimerDecimalPlaces, timeRemaining)
		timerData.timerLabel.Text = timerText

		-- play tick sound if applicable
		local fullSecondsLeft = math.floor(timeRemaining)
		if not timerData.lastFullSecond or timerData.lastFullSecond ~= fullSecondsLeft then
			timerData.lastFullSecond = fullSecondsLeft
			morpherButton.sounds.tick:Play()
		end

		debug.profileend()
	end

	local function copyProperties(from: BasePart, to: BasePart)
		to.Color = from.Color
		to.CFrame = from.CFrame
		to.CanCollide = from.CanCollide
		to.Size = from.Size
		to.Transparency = from.Transparency
		to.Material = from.Material

		-- i brought this function back because Instance.fromExisting doesn't
		-- copy over tags & attributes
		utility.Functions.copyCAT(from, to)
	end

	local function updateMainMorph(morpherButton: MorpherButton, newMorph: BasePart)
		local tweenInfo = getTweenInfo(morpherButton)

		-- button color tween
		for _, buttonPart in morpherButton.buttonParts do
			utility.Functions.tween(
				buttonPart,
				tweenInfo.Time,
				{ Color = newMorph.Color },
				tweenInfo.EasingStyle,
				tweenInfo.EasingDirection
			)
		end

		-- update morph if it's a different part type
		local morphPart = morpherButton.morphPart
		if
			morphPart.ClassName ~= newMorph.ClassName
			or (morphPart:IsA("Part") and newMorph:IsA("Part") and morphPart.Shape ~= newMorph.Shape)
		then
			local morphClone = newMorph:Clone()
			morphClone.Name = "Morph"
			copyProperties(morphPart, morphClone)
			morphClone.Parent = morpherButton.morpher

			morphPart:Destroy()
			morphPart = morphClone
			morpherButton.morphPart = morphPart
		end

		-- move all the morphs to the new morph
		morphPart.Material = newMorph.Material
		createLerp(morpherButton, { morphPart, table.unpack(morpherButton.cloneMorphs) }, newMorph, tweenInfo)

		-- destroy clone morphs
		for _, cloneMorph in morpherButton.cloneMorphs do
			task.spawn(function()
				task.wait(morpherButton.MoveTween.Time)
				cloneMorph:Destroy()
			end)
		end
	end

	local function createCloneMorph(morpherButton: MorpherButton, newMorph: BasePart)
		local cloneMorph = newMorph:Clone()
		cloneMorph.Name = "CloneMorph"
		copyProperties(morpherButton.morphPart, cloneMorph)
		cloneMorph.Material = newMorph.Material
		cloneMorph.Parent = morpherButton.morpher

		local tweenInfo = getTweenInfo(morpherButton)
		createLerp(morpherButton, { cloneMorph }, newMorph, tweenInfo)

		table.insert(morpherButton.cloneMorphs, cloneMorph)
	end

	local function setupMorpherTimer(morpherButton: MorpherButton)
		-- set up timer label
		local billboard = morpherButton.durationGui:Clone()
		local timerLabel = billboard:FindFirstChild("TimerLabel")

		if not timerLabel or not timerLabel:IsA("TextLabel") then
			rootScope:log({
				"Morpher's DurationGui is either missing its TimerLabel TextLabel or has it set up incorrectly.",
				`Path: {morpherButton.morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		billboard.Parent = morpherButton.lastTouchedButtonPart
		billboard.Enabled = true

		-- set up timer table
		local timerData: MorpherTimer = {
			startTime = os.clock(),
			durationBillboard = billboard,
			timerLabel = timerLabel,
		}
		morpherButton.timerData = timerData
	end

	local function activateButton(morpherButton: MorpherButton)
		if morpherButton == cache.currentMorpherButtons[morpherButton.morpherID] then
			return
		end

		-- update current button
		local oldButton = cache.currentMorpherButtons[morpherButton.morpherID]
		cache.currentMorpherButtons[morpherButton.morpherID] = morpherButton

		-- deactivate the old button and play sound
		if oldButton then
			deactivateButton(oldButton)
		end
		playPressSound(morpherButton)

		-- update morph parts
		for index, newMorph in morpherButton.newMorphParts do
			if index == 1 then
				updateMainMorph(morpherButton, newMorph)
			else
				createCloneMorph(morpherButton, newMorph)
			end
		end

		-- set up timer if it's enabled
		if morpherButton.buttonConfiguration.Timer > 0 then
			setupMorpherTimer(morpherButton)
		end
	end

	local function onButtonTouched(morpherButton: MorpherButton, touchedButton: BasePart, touchingPart: BasePart)
		if not utility.ClientObjects.evaluateToucher(touchedButton, touchingPart, morpherButton.touchConfiguration) then
			return
		end

		morpherButton.lastTouchedButtonPart = touchedButton
		activateButton(morpherButton)
	end

	local Config = utility.Config
	local function setupMorpherButton(
		morpherButton: Model,
		morpherID: string,
		morpher,
		defaultMorph,
		morphPart,
		cloneMorphs,
		durationGui,
		scope: _T.Scope
	)
		local buttonConfigObject = morpherButton:FindFirstChild("MorpherButtonConfiguration")
		if not buttonConfigObject then
			return
		end
		
		if not cache.morpherButtons[morpherID] then
			cache.morpherButtons[morpherID] = {}
		end

		--> set up button
		local buttonParts: { BasePart } = {}
		local newMorphs: { BasePart } = {}

		local buttonConfiguration = Config.GetConfig(scope, buttonConfigObject, BUTTON_CONFIG_TEMPLATE):ObserveChanges()

		local touchConfiguration =
			Config.GetConfig(scope, buttonConfigObject:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
				:ObserveChanges()

		local moveTweenConfiguration =
			Config.GetConfig(scope, buttonConfigObject:FindFirstChild("MoveTweenConfiguration"), Config.TWEEN_CONFIG)
				:ObserveChanges()
		local returnTweenConfiguration =
			Config.GetConfig(scope, buttonConfigObject:FindFirstChild("ReturnTweenConfiguration"), Config.TWEEN_CONFIG)
				:ObserveChanges()

		local pressSound = buttonConfigObject:FindFirstChild("Press")
		local tickSound = buttonConfigObject:FindFirstChild("Tick")

		if not pressSound or not pressSound:IsA("Sound") then
			scope:log({
				"A morpher button is either missing its Press sound or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		if not tickSound or not tickSound:IsA("Sound") then
			scope:log({
				"A morpher button is either missing its Tick sound or has it set up incorrectly.",
				`Path: {morpher:GetFullName()}`,
				type = "warn",
			})
			return
		end

		for _, object in morpherButton:GetChildren() do
			if object:IsA("BasePart") then
				if object.Name == "Button" then
					table.insert(buttonParts, object)
				elseif object.Name == "NewMorph" then
					object.Transparency = 1
					table.insert(newMorphs, object)
				end
			end
		end

		local buttonTable = {
			morpherID = morpherID,
			button = morpherButton,
			buttonParts = buttonParts,
			newMorphParts = newMorphs,
			buttonConfiguration = buttonConfiguration,
			touchConfiguration = touchConfiguration,
			sounds = { press = pressSound, tick = tickSound },

			morpher = morpher,
			morphPart = morphPart,
			defaultMorph = defaultMorph,
			cloneMorphs = cloneMorphs,
			durationGui = durationGui,

			MoveTween = moveTweenConfiguration,
			ReturnTween = returnTweenConfiguration,
		} :: MorpherButton
		function buttonTable.activate()
			buttonTable.lastTouchedButtonPart = buttonParts[1]
			activateButton(buttonTable)
		end

		table.insert(cache.morpherButtons[morpherID], buttonTable)
		cache.morpherLerps[morpherID] = {}

		--> set up touching
		for _, buttonPart in buttonParts do
			scope:add(buttonPart.Touched:Connect(function(touchingPart)
				onButtonTouched(buttonTable, buttonPart, touchingPart)
			end))

			if touchConfiguration.canFlip then
				scope:add(utility.ClientObjects.bindToFlip(buttonPart, function()
					buttonTable.lastTouchedButtonPart = buttonPart
					activateButton(buttonTable)
				end))
			end
		end

		scope:add(function()
			cache.currentMorpherButtons[morpherID] = nil
			cache.morpherLerps[morpherID] = nil

			local thisCache = cache.morpherButtons[morpherID]
			local index = table.find(thisCache, buttonTable)
			if index then
				table.remove(thisCache, index)
			end
			if #thisCache <= 0 then
				cache.morpherButtons[morpherID] = nil
			end

			table.clear(buttonTable)
			buttonTable = nil :: any
		end)
	end

	cache.setupMorpherButton = setupMorpherButton

	local isTableEmpty = utility.Table.IsEmpty
	rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
		if isTableEmpty(cache) or isTableEmpty(cache.morpherButtons) then
			return
		end

		debug.profilebegin("Morpher -> Update Lerps")
		for _, lerps in cache.morpherLerps do
			for _, morpherLerp in lerps do
				updateMorpherLerp(morpherLerp, deltaTime)
			end
		end
		debug.profileend()

		debug.profilebegin("Morpher -> Update Timers")
		for _, buttons in cache.morpherButtons do
			for _, morpherButton in buttons do
				if morpherButton.timerData then
					updateMorpherTimer(morpherButton)
				end
			end
		end
		debug.profileend()
	end))

	SequencerSupport(rootScope, utility, cache)
	return cache
end

function Morpher.Run(scope: _T.Scope, utility: _T.Utility)
	local morpherConfig = scope.instance
	if not morpherConfig or not morpherConfig.Parent then
		return
	end

	local morpherID = utility.Functions.generateUID()
	local morpher = morpherConfig.Parent
	scope:attach(morpher)

	--> Get Cache
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleMorpherCache)

	--> Variables
	local morphPart = morpher:FindFirstChild("Morph")
	local cloneMorphs: { BasePart } = {}
	local durationGui = morpherConfig:FindFirstChild("DurationGui")

	--> Check for problems
	if not morphPart or not morphPart:IsA("BasePart") then
		scope:log({
			"Morpher is either missing its Morph part or has it set up incorrectly.",
			`Path: {morpher:GetFullName()}`,
			type = "warn",
		})
		return
	end

	if not durationGui or not durationGui:IsA("BillboardGui") then
		scope:log({
			"Morpher is either missing its DurationGui BillboardGui or has it set up incorrectly.",
			`Path: {morpher:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Set up default morph
	local defaultMorph = morphPart:Clone()
	defaultMorph.Name = "DefaultMorph"
	defaultMorph.Transparency = 1
	defaultMorph.CanCollide = false
	defaultMorph.Anchored = true
	defaultMorph:ClearAllChildren()
	defaultMorph.Parent = morpher

	--> Set up morpher buttons
	for _, object in morpher:GetChildren() do
		if object.Name == "Button" and object:IsA("Model") then
			cache.setupMorpherButton(
				object,
				morpherID,
				morpher,
				defaultMorph,
				morphPart,
				cloneMorphs,
				durationGui,
				scope
			)
		end
	end
end

return Morpher
