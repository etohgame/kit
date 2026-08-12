--!strict
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Character = require(script.Parent.Character)

--[=[
    @class JumpButton
    @client
    A way of checking if the player is holding down the jump button.
]=]
local JumpButton = {}

local JUMP_EVENT = Instance.new("BindableEvent")
JUMP_EVENT.Parent = script

local isDown = false
JumpButton.JumpEvent = JUMP_EVENT

--[=[
    @within JumpButton
    
    Returns whether the jump button is currently being held down.
]=]
function JumpButton.IsDown(): boolean
	return isDown
end

local characterInstances = Character.getCharacter()
RunService:BindToRenderStep("CharacterJumpDetection", Enum.RenderPriority.Character.Value, function()
	debug.profilebegin("Utility -> JumpButton Detection")

	local humanoid = characterInstances.humanoid
	if not humanoid then
		debug.profileend()
		return
	end

	local isJumping = humanoid.Jump
	if isDown ~= isJumping then
		isDown = isJumping
		JUMP_EVENT:Fire(isJumping)
	end

	debug.profileend()
end)

return table.freeze(JumpButton)
