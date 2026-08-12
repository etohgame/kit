--!strict
--!optimize 2
--@version 6.1.2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local _TDefs = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)

local Utility = require(ReplicatedStorage.Framework.Kit.Utility)

local Boost = {}

Boost.Information = {
	icon = "rbxassetid://14549056586",
	color = Color3.fromRGB(175, 255, 0),
}

function Boost.Start(boostData: _TDefs.BoostData)
	
end

function Boost.Update(boostData: _TDefs.BoostData)
	Utility.Character.changeHumanoidProperty(
		"JumpPower",
		boostData.power,
		boostData.startTweenInfo
	)
end

function Boost.End(boostData: _TDefs.BoostData)
	local activeBoost = Utility.Character.getActiveBoost(boostData.type)
	local defaultJumpPower = if activeBoost then activeBoost.power else StarterPlayer.CharacterJumpPower
	
	Utility.Character.changeHumanoidProperty(
		"JumpPower",
		defaultJumpPower,
		boostData.endTweenInfo
	)
end

function Boost.GetMultiplier(boostData: _TDefs.BoostData): number
	return math.max(boostData.power / StarterPlayer.CharacterJumpPower, 0)
end

return Boost