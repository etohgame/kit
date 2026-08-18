--!strict
--!optimize 2
-- By @synnwave, Camille (09/12/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

--[=[
    @class GuiManager
    @client
    
    Manager module for GUIs (mainly EffectGui), used for things such as the boost & key display.
]=]

--[[
---------------------------------------------------------------------------
Services, modules and other objects
---------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local Kit = Framework.Kit
local Log = require(Framework.Log)
local CharacterManager_Types = require(Kit.Managers.CharacterManager.TypeDefs)
local KitSettings = require(ReplicatedStorage.KitSettings)

local localPlayer = Players.LocalPlayer :: Player

--[[
---------------------------------------------------------------------------
Main table
---------------------------------------------------------------------------
]]

local GuiManager = {
	__initialized = false,

	KeyDisplayLimit = 5,
	__keyCaches = {},
} :: _TDefs.GuiManager

--[[
---------------------------------------------------------------------------
Variables, types and constants
---------------------------------------------------------------------------
]]

local boostID = 0 -- used for LayoutOrder of boost timers

local BOOST_FRAME_INACTIVE_SIZE = UDim2.fromScale(0, script.BoostFrame.Size.Y.Scale)
local BOOST_FRAME_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local KEY_CAMERA = Instance.new("Camera")
KEY_CAMERA.CFrame = CFrame.new(Vector3.zAxis * 4)

--[[
---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------
]]

function roundDecimals(value: number, decimals: number): number
	local mult = 10 ^ decimals
	return math.round(value * mult) / mult
end

--[=[
	@within GuiManager
	
	Creates and returns a boost timer frame for the given `boostType`.
]=]
function GuiManager:CreateBoostFrame(boostData: CharacterManager_Types.BoostData): _TDefs.BoostTimerFrame?
	if boostData.hideGUI then
		return nil-- don't make one if they disabled it
	end

	boostID += 1

	local frame = script.BoostFrame:Clone()
	frame.Size = BOOST_FRAME_INACTIVE_SIZE
	frame.Name = boostData.type

	local timerFrame = frame.Timer
	local icon = frame.Icon
	-- timer
	timerFrame.Visible = boostData.mode == "Default"
	timerFrame.Fill.BackgroundColor3 = boostData.module.Information.color
	timerFrame.Remaining.TextColor3 = boostData.module.Information.color

	-- icon
	icon.ImageColor3 = boostData.module.Information.color
	icon.Image = boostData.module.Information.icon

	-- power text
	icon.Power.TextColor3 = boostData.module.Information.color

	frame.LayoutOrder = -boostID
	frame.Parent = GuiManager.Gui.Boosts

	boostData.frame = frame :: _TDefs.BoostTimerFrame?
	TweenService:Create(frame, BOOST_FRAME_TWEEN_INFO, { Size = script.BoostFrame.Size }):Play()

	GuiManager:UpdateBoostFrame(boostData)
	return frame
end

--[=[
	@within GuiManager
	
	Updates a boost's timer frame.
]=]
function GuiManager:UpdateBoostFrame(boostData: CharacterManager_Types.BoostData)
	local frame = boostData.frame
	if not frame then
		return
	end

	local timerFrame = frame.Timer

	-- timer text
	timerFrame.Remaining.Text = GuiManager:FormatBoostTimer(boostData)

	-- timer bar
	local fraction = math.clamp(boostData.timeLeft / boostData.duration, 0, 1)
	timerFrame.Fill.Size = UDim2.fromScale(fraction, 1)

	-- power text
	local powerLabel = frame.Icon.Power
	local finalText = ""
	if boostData.multiplier then
		powerLabel.Visible = boostData.multiplier ~= -1
		finalText = `{tostring(roundDecimals(boostData.multiplier, 2))}x`
	end

	if powerLabel.Text ~= finalText then
		powerLabel.Text = finalText
	end
end

--[=[
	@within GuiManager
	
	Helper function that formats a boost's remaining time into a string.
]=]
function GuiManager:FormatBoostTimer(boostData: CharacterManager_Types.BoostData): string
	return if boostData.infinite then "∞" else tostring(roundDecimals(boostData.timeLeft, boostData.timerDecimals))
end

--[=[
	@within GuiManager
	
	Destroys the given boost's timer frame, fading it out and deleting it when finished
]=]
function GuiManager:DestroyBoostFrame(boostData: CharacterManager_Types.BoostData)
	local frame = boostData.frame
	if not frame then
		return
	end

	local tween = TweenService:Create(frame, BOOST_FRAME_TWEEN_INFO, { Size = BOOST_FRAME_INACTIVE_SIZE })
	tween:Play()
	tween.Completed:Once(function()
		frame:Destroy()
	end)
end

--[=[
	@within GuiManager
	
	Binds the given `cache` to the key cache.
]=]
function GuiManager:BindKeyCache(cache: _TDefs.KeyCache)
	self.__keyCaches[cache.id] = cache
end

--[=[
	@within GuiManager
	
	Unbinds the given `cache` from the key cache.
]=]
function GuiManager:UnbindKeyCache(cache: _TDefs.KeyCache)
	self.__keyCaches[cache.id] = nil
end

function GuiManager:__updateKeyDisplay()
	debug.profilebegin("GuiManager > Key Display")
	
	if not self.Gui then
		debug.profileend()
		return
	end
	
	local keyFrame = self.Gui:FindFirstChild("Keys")
	if not keyFrame then
		debug.profileend()
		return
	end

	local characterCFrame
	local character = (Players.LocalPlayer :: Player).Character
	if character then
		characterCFrame = character:GetPivot()
	end

	local displayLimit = self.KeyDisplayLimit
	for cacheId, cache in self.__keyCaches do
		for keyId, key in cache.keys do
			debug.profilebegin("GuiManager > Key Display > Manage Key")

			if not key or not key.__private then
				debug.profileend()
				continue
			end
			local keyData = key.__private
			if not key.instance or not keyData.viewport then
				debug.profileend()
				continue
			end

			local viewport = keyData.viewport
			if viewport.Parent ~= keyFrame then
				viewport.Parent = keyFrame
			end
			if not viewport.CurrentCamera then
				viewport.CurrentCamera = KEY_CAMERA
			end

			local keyIndex = table.find(cache.activeKeys, keyId)
			if keyIndex ~= nil and keyIndex >= displayLimit and not keyData.used then
				if viewport.LayoutOrder ~= keyIndex then
					viewport.LayoutOrder = keyIndex
				end
				if key.instance.Parent ~= viewport then
					key.instance.Parent = viewport
					if not keyData.isViewportDisplayed then
						keyData.isViewportDisplayed = true
						key.instance:PivotTo(key.config.ViewportOffset or CFrame.identity)
					end
				end

				local timerLabel = key.timerLabel
				if keyData.startTimer and timerLabel then
					viewport.Time.Text = timerLabel.Text
				end

				if not viewport.Visible then
					viewport.Visible = true
				end
			else
				if viewport.Visible then
					viewport.Visible = false
				end

				local currentParent = key.instance.Parent
				if currentParent and currentParent ~= keyData.parent then
					key.instance.Parent = keyData.parent
				end

				if keyData.isViewportDisplayed then
					keyData.isViewportDisplayed = false
					key.instance:PivotTo(characterCFrame or key.originalCFrame)
				end
			end

			debug.profileend()
		end
	end

	debug.profileend()
end

--[=[
	@within GuiManager
	
	Displays the GUI with the given `guiName` on the player's screen.
]=]
function GuiManager:DisplayGUI(guiName: string, ...: any)
	local gui = script:FindFirstChild(guiName)
	if not gui or not gui:IsA("ScreenGui") then -- already being displayed?
		Log({
			`{guiName} GUI not found or already visible!!`,
			type = "warn",
		})
		return
	end

	if guiName == "debug" then
		local displayMemory = ...
		(gui :: typeof(script.debug)).memory.Visible = displayMemory
		do (gui :: typeof(script.debug)).memory.LocalScript.Enabled = displayMemory end
	end

	gui.Enabled = true
	gui.Parent = GuiManager.PlayerGui
end

function GuiManager:Init()
	if self.__initialized then
		return GuiManager
	end
	self.__initialized = true

	local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
	task.spawn(function()
		GuiManager.Gui = playerGui:WaitForChild("EffectGUI", 5) :: index<_TDefs.GuiManager, "Gui">
	end)
	GuiManager.PlayerGui = playerGui

	--> Detect any new EffectGUIs
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "EffectGUI" then
			GuiManager.Gui = child :: index<_TDefs.GuiManager, "Gui">
		end
	end)

	--> Debug & Settings Gui Init
	if KitSettings.DisplayDebugGuis then
		GuiManager:DisplayGUI("debug", KitSettings.DisplayMemoryDebug)
	end
	if KitSettings.DisplaySettingsGui then
		GuiManager:DisplayGUI("settings")
	end
	TextChatService.SendingMessage:Connect(function(message)
		if message.Text:lower() == ".debug" then
			GuiManager:DisplayGUI("debug", true)
		elseif message.Text:lower() == ".kitsettings" then
			GuiManager:DisplayGUI("settings")
		end
	end)

	--> Start Key display loop
	RunService.Heartbeat:Connect(function()
		self:__updateKeyDisplay()
	end)

	return GuiManager
end

return GuiManager
