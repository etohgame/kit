--!strict
--!optimize 2
-- By @synnwave (09/12/24 DD/MM/YY)

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
    @class FlipManager
    @client
    Manager module responsible for handling corner flips.
]=]

--[[
---------------------------------------------------------------------------
Services, modules and other objects
---------------------------------------------------------------------------
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)
local PropertyUtil = require(Framework.Kit.Utility.Property)

--[[
---------------------------------------------------------------------------
Constants
---------------------------------------------------------------------------
]]

local DEFAULT_FLIP_SOUND = script:WaitForChild("DoNotChange")

local PARAMS = OverlapParams.new()
PARAMS.CollisionGroup = "" -- disable the collisiongroup check
-- or else it won't work with collisiongroups other than Default

--[[
---------------------------------------------------------------------------
Main table
---------------------------------------------------------------------------
]]

local FlipManager = {
	__initialized = false,
	__callbacks = {},
	Binds = { Keyboard = Enum.KeyCode.F, Controller = Enum.KeyCode.ButtonX },
} :: _TDefs.FlipManager

--[[
---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------
]]

local localPlayer = Players.LocalPlayer :: Player

local flipCooldowns = {}

--[=[
	@within FlipManager
	
	Performs a corner flip on any flip parts the player is touching.
	Parts can be marked as flip parts by:
	* Adding a Tag or `Instance` inside the part called `CanFlip`
	* Adding a callback on the part with `FlipManager:BindToFlip()`
	
	If the flip part has a `TeleToObject` `ObjectValue` present and set, the player
	will teleport to that object rather than to the other end of the flip part.
	
	If the flip part has a `FlipSound` `Sound` present, that sound will be played
	instead of the default sound.
]=]
function FlipManager:TryFlip()
	local character = localPlayer.Character
	if not character then
		return
	end
	local torso = character:FindFirstChild("Torso")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not (torso and torso:IsA("BasePart")) or not (rootPart and rootPart:IsA("BasePart")) then
		return
	end

	for _, touchingPart in Workspace:GetPartsInPart(torso, PARAMS) do
		if
			(
				not touchingPart:HasTag("CanFlip")
				and not touchingPart:FindFirstChild("CanFlip")
				and FlipManager.__callbacks[touchingPart] == nil
			)
			or touchingPart:GetAttribute("Activated") == false
			or flipCooldowns[touchingPart]
		then
			continue
		end

		flipCooldowns[touchingPart] = true
		task.delay(PropertyUtil.assureAttribute(touchingPart, "FlipCooldown", 0), function()
			flipCooldowns[touchingPart] = nil
		end)

		local teleportPart: BasePart = touchingPart
		if not touchingPart:HasTag("DoNotFlipPlayer") then
			local teleportToObject = touchingPart:FindFirstChild("TeleToObject")
			if
				teleportToObject
				and teleportToObject:IsA("ObjectValue")
				and teleportToObject.Value
				and (teleportToObject.Value :: Instance):IsA("BasePart")
			then
				teleportPart = teleportToObject.Value :: BasePart
			elseif teleportToObject then
				warn("blank", teleportToObject, "value")
				return
			end

			local offsetFromPart = touchingPart.CFrame:ToObjectSpace(torso.CFrame)
			torso.CFrame = (teleportPart.CFrame * CFrame.Angles(0, math.pi, 0)) * offsetFromPart
		end

		local callbacks = FlipManager.__callbacks[touchingPart]
		if callbacks then
			for _, callback in callbacks do
				if typeof(callback) == "function" then
					task.spawn(callback, rootPart)
				end
			end
		end

		local sound = (touchingPart:FindFirstChild("FlipSound") or DEFAULT_FLIP_SOUND)
		if sound and sound:IsA("Sound") then
			sound = sound:Clone()
			sound.Parent = teleportPart
			sound:Play()
			task.delay(sound.TimeLength / sound.PlaybackSpeed, function()
				sound:Destroy()
			end)
		end
	end
end

local function doNothing() end

--[=[
	@within FlipManager
	
	Binds the `callback` function to the `part`, executing the callback when
	the player performs a corner flip on it.
	
	** Please add this to your Scope! **
]=]
function FlipManager:BindToFlip(part: BasePart, callback: (rootPart: BasePart) -> ())
	if not (typeof(part) == "Instance" and part:IsA("BasePart")) or typeof(callback) ~= "function" then
		return doNothing
	end

	local callbacks = FlipManager.__callbacks
	local callbackID: string? = HttpService:GenerateGUID()
	if not callbacks[part] then
		callbacks[part] = {}
	end
	callbacks[part][callbackID] = callback

	return function()
		if not callbackID then
			return
		end
		callbacks[part][callbackID] = nil
		callbackID = nil
		if next(callbacks[part]) == nil then
			callbacks[part] = nil
		end
	end
end

function FlipManager:Init()
	if self.__initialized then
		return FlipManager
	end
	self.__initialized = true

	local ChatInputBarConfiguration = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if
			(gameProcessedEvent or ChatInputBarConfiguration.IsFocused)
			or (
				FlipManager.Binds.Keyboard ~= input.KeyCode
				and FlipManager.Binds.Keyboard ~= input.UserInputType
				and FlipManager.Binds.Controller ~= input.KeyCode
			)
		then
			return
		end
		
		FlipManager:TryFlip()
	end)
	
	UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
		if processedByUI then
			return
		end
		FlipManager:TryFlip()
	end)
	
	return FlipManager
end

return FlipManager
