--!strict
--!optimize 2
--@version 6.1.2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local _TDefs = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)

local Utility = require(ReplicatedStorage.Framework.Kit.Utility)

local Boost = {}

Boost.Information = {
	icon = "rbxassetid://13492318225",
	color = Color3.fromRGB(255, 255, 0),
}

function Boost.Start(boostData: _TDefs.BoostData)
	
end

function Boost.Update(boostData: _TDefs.BoostData)
	Utility.Character.changeHumanoidProperty(
		"WalkSpeed",
		boostData.power,
		boostData.startTweenInfo
	)
end

function Boost.End(boostData: _TDefs.BoostData)
	local activeBoost = Utility.Character.getActiveBoost(boostData.type)
	local defaultWalkSpeed = if activeBoost then activeBoost.power else StarterPlayer.CharacterWalkSpeed
	
	Utility.Character.changeHumanoidProperty(
		"WalkSpeed",
		defaultWalkSpeed,
		boostData.endTweenInfo
	)
end

function Boost.GetMultiplier(boostData: _TDefs.BoostData): number
	return math.max(boostData.power / StarterPlayer.CharacterWalkSpeed, 0)
end

return Boost