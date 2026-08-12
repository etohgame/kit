--!strict
--!optimize 2
--@version conveyor-6.1.0
--@creator aamo_s
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type ConveyorData = {
	conveyor: BasePart,
	beams: { Beam },
	speed: number,
}

type ConveyorCache = { [any]: ConveyorData }

local function setConveyorSpeed(conveyor: BasePart, beams: { Beam }, speed: number)
	conveyor.AssemblyLinearVelocity = conveyor.CFrame.LookVector * speed
	for _, beam in beams do
		beam.TextureSpeed = speed / beam.TextureLength
	end
end

local Conveyor = {
	CanQueue = true,
	RunOnStart = false,
}

local CONVEYOR_CONFIG_TEMPLATE = {
	Speed = 10,
}

local function handleCache(rootScope: _T.Scope)
	local conveyorCache = {} :: ConveyorCache
	rootScope:add(RunService.PostSimulation:Connect(function()
		for id, data in conveyorCache do
			if not data.conveyor:IsDescendantOf(Workspace) or data.conveyor.Anchored then
				conveyorCache[id] = nil
				continue
			end

			setConveyorSpeed(data.conveyor, data.beams, data.speed)
		end
	end))

	return conveyorCache
end

function Conveyor.Run(scope: _T.Scope, utility: _T.Utility)
	local conveyorConfig = scope.instance
	if not conveyorConfig then
		return
	end

	local conveyor = conveyorConfig.Parent
	if not conveyor or not conveyor:IsA("BasePart") then
		return
	end

	local beams = {}

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, conveyorConfig, CONVEYOR_CONFIG_TEMPLATE)
		:ObserveChanges(function(key, value)
			if key == "Speed" then
				setConveyorSpeed(conveyor, beams, value)
			end
		end)

	--> Get Cache
	local conveyorCache = utility.Scope.getCached(scope, "conveyorCache", handleCache)

	for _, v in conveyor:GetChildren() do
		if not v:IsA("Beam") then
			continue
		end

		table.insert(beams, v)
	end

	local function updateConveyor()
		conveyorCache[conveyor] = {
			conveyor = conveyor,
			beams = beams,
			speed = configuration.Speed,
		}
	end

	local anchoredScope = scope:inherit()
	anchoredScope:attach(conveyor, true)
	anchoredScope:add(conveyor:GetPropertyChangedSignal("Anchored"):Connect(function()
		if conveyor.Anchored then
			setConveyorSpeed(conveyor, beams, configuration.Speed)
		else
			updateConveyor()
		end
	end))

	setConveyorSpeed(conveyor, beams, configuration.Speed)
	updateConveyor()
	scope:add(function()
		conveyorCache[conveyor] = nil
	end)
end

return Conveyor
