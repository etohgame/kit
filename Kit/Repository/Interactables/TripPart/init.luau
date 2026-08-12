--!strict
--!optimize 2
--@version trippart-6.1.3
--@creator Gammattor
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
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local TripPart = {
	CanQueue = true,
	RunOnStart = false,
}

local PART_CONFIG_TEMPLATE = {
	Cooldown = 1,
	StunDuration = 0,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function TripPart.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local tripPartConfig = scope.instance
	if not tripPartConfig then
		return
	end

	local tripPart = tripPartConfig.Parent
	if not tripPart or not tripPart:IsA("BasePart") then
		return
	end

	--> Get Configuration
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, tripPartConfig, PART_CONFIG_TEMPLATE):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, tripPartConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	--> Main Functionality
	local tripCooldown = false
	local function trip()
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			return
		end

		local property = if configuration.StunDuration > 0 then "PlatformStand" else "Sit"
		if tripCooldown or utility.Property.getPropertySafe(humanoid, property) then
			return
		end

		tripCooldown = true
		task.delay(configuration.Cooldown, function()
			tripCooldown = false
		end)
		
		utility.Property.setPropertySafe(humanoid, property, true)

		if property == "PlatformStand" then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			task.delay(configuration.StunDuration, function()
				utility.Property.setPropertySafe(humanoid, property, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end)
		end
	end

	scope:attach(tripPart)
	scope:add(tripPart.Touched:Connect(function(toucher)
		if utility.ClientObjects.evaluateToucher(tripPart, toucher, touchConfiguration) and not tripCooldown then
			trip()
		end
	end))

	if touchConfiguration.canFlip then
		tripPart:AddTag("DoNotFlipPlayer")
		scope:add(utility.ClientObjects.bindToFlip(tripPart, function()
			if tripCooldown then
				return
			end

			trip()
		end))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[tripPart] = trip
	scope:add(function()
		cache[tripPart] = nil
		cache = nil :: any
	end)
end

return TripPart
