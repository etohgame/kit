--!strict
--!optimize 2
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

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid: Humanoid? = character:WaitForChild("Humanoid")
if not humanoid then
	return
end

-- Head collision glitch fix
local head = character:FindFirstChild("Head")
if head and head:IsA("BasePart") then
	head:GetPropertyChangedSignal("CanCollide"):Connect(function()
		head.CanCollide = true
	end)
end

-- Truss Fix
-- Original script by AkaWhats (& some help by MasSpartan)
-- Code touchups & some micro-optimizations done by synnwave

local DEFAULT_FPS = 1 / 60
local TRIGGER_FPS = 1 / 75
local STATES = {
    [Enum.HumanoidStateType.Jumping] = true,
    [Enum.HumanoidStateType.Climbing] = true,
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.Landed] = true,
    [Enum.HumanoidStateType.Seated] = true,
    [Enum.HumanoidStateType.Swimming] = true,
    [Enum.HumanoidStateType.GettingUp] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.Flying] = true,
    [Enum.HumanoidStateType.PlatformStanding] = true,

    [Enum.HumanoidStateType.Running] = false,
}

local fps
local function onStateChanged(oldState, newState)
    if newState ~= oldState and STATES[newState] then
        for state, allowed in STATES do
            if allowed and state ~= newState then
                humanoid:SetStateEnabled(state, false)
            end
        end
        task.wait(DEFAULT_FPS - fps)
        for state, allowed in STATES do
            if allowed and state ~= newState then
                humanoid:SetStateEnabled(state, true)
            end
        end
    end
end

local stateConnection: RBXScriptConnection?
RunService.Heartbeat:Connect(function(delta: number)
	debug.profilebegin("Truss Fix > Update")

	if delta < TRIGGER_FPS then
		fps = delta
		if stateConnection == nil then
			stateConnection = humanoid.StateChanged:Connect(onStateChanged)
		end
	elseif delta > TRIGGER_FPS and stateConnection ~= nil then
		stateConnection:Disconnect()
		stateConnection = nil
	end

	debug.profileend()
end)
