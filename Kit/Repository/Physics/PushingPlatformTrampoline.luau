--!strict
--!optimize 2
--@version pushingplatformtrampoline-6.0.0
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
local Workspace = game:GetService("Workspace")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local PushingPlatformTrampoline = {
	CanQueue = true,
	RunOnStart = false,
}

local PLATFORM_CONFIG_TEMPLATE = {
	LaunchSpeed = 1,
}

function PushingPlatformTrampoline.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local trampolineConfig = scope.instance
	if not trampolineConfig then
		return
	end

	local trampoline = trampolineConfig.Parent
	if not trampoline then
		return
	end

	local anchor = nil
	local base = nil
	local prismatic = nil
	local vectorForce = nil
	local lowerLimit = nil
	local upperLimit = nil

	local active = false

	scope:attach(trampoline)

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, trampolineConfig, PLATFORM_CONFIG_TEMPLATE):ObserveChanges()

	--> Get objects and check for problems
	do
		anchor = trampoline:FindFirstChild("Anchor")
		if not anchor or not anchor:IsA("BasePart") then
			scope:log({
				"PushingPlatformTrampoline is either missing its Anchor part or has it set up incorrectly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		base = trampoline:FindFirstChild("Base")
		if not base or not base:IsA("BasePart") then
			scope:log({
				"PushingPlatformTrampoline is either missing its Base part or has it set up incorrectly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		prismatic = anchor:FindFirstChildOfClass("PrismaticConstraint")
		if not prismatic then
			scope:log({
				"PushingPlatformTrampoline is missing its PrismaticConstraint and cannot function correctly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		vectorForce = base:FindFirstChildOfClass("VectorForce")
		if not vectorForce then
			scope:log({
				"PushingPlatformTrampoline is missing its VectorForce and cannot function correctly.",
				`Path: {trampoline:GetFullName()}`,
				type = "warn",
			})
			return
		end

		upperLimit = prismatic.UpperLimit - 0.2
		lowerLimit = prismatic.LowerLimit + 0.2
	end

	--> Setup beam if possible
	local indicatorBeam = trampoline:FindFirstChild("TrampolineBeam", true)
	local beamAttachment1 = anchor:FindFirstChild("BeamAttachment1")

	if (indicatorBeam and indicatorBeam:IsA("Beam")) and (beamAttachment1 and beamAttachment1:IsA("Attachment")) then
		indicatorBeam.Attachment1 = beamAttachment1
		beamAttachment1.CFrame = CFrame.new(Vector3.yAxis * -upperLimit)
	end

	--> Setup total mass
	local totalMass = 0
	for _, obj in trampoline:GetDescendants() do
		if obj:IsA("BasePart") and not obj.Anchored then
			totalMass += obj.Mass * Workspace.Gravity
		end
	end

	--> Setup default force
	local defaultForce = Vector3.zAxis * totalMass + (Vector3.zAxis * 100)
	vectorForce.Force = defaultForce

	--> Functions
	local function activate()
		active = true
		vectorForce.Force = defaultForce * (3 * configuration.LaunchSpeed)

		local waitLoop
		waitLoop = scope:add(RunService.Stepped:Connect(function()
			if prismatic.CurrentPosition <= lowerLimit then
				scope:remove(waitLoop)

				vectorForce.Force = defaultForce
				active = false
			end
		end))
	end

	--> Main loop
	scope:add(RunService.Stepped:Connect(function()
		if active then
			return
		end

		if prismatic.CurrentPosition >= upperLimit then
			activate()
		end
	end))
end

return PushingPlatformTrampoline
