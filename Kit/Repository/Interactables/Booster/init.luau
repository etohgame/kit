--!strict
--!optimize 2
--@version booster-6.1.3
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

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local CharacterManager_Types = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)
local SequencerSupport = require(script.SequencerSupport)

type Booster = {
	hitbox: BasePart,
	configuration: { [string]: any },
	extraVariables: { [string]: any},
	startTweenConfig: { [string]: any },
	endTweenConfig: { [string]: any },
	id: string,
}

type BoosterCache = {
	activators: { [BasePart]: () -> () },
	boosters: { Booster },
	activeBoosters: { [string]: Booster? },
}

local Booster = {
	CanQueue = true,
	RunOnStart = false,
}

local BOOSTER_CONFIG_TEMPLATE
function Booster.Init(utility: _T.Utility)
	local Config = utility.Config
	BOOSTER_CONFIG_TEMPLATE = {
		Mode = Config.Type.Some("Default", "Pad", "Zone", Config.Type.none),
		Type = "Unknown",
		Duration = 5,
		Power = 50,
		TimerDecimals = 1,
		HideGUI = false,
		PadDistance = 10,
	}
end

local player = Players.LocalPlayer
function Booster.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local boosterConfig = scope.instance
	if not boosterConfig then
		return
	end

	local booster = boosterConfig.Parent
	if not booster or not booster:IsA("BasePart") then
		return
	end

	local CharacterUtil = utility.Character
	local ClientObjectUtil = utility.ClientObjects
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boosterConfig, BOOSTER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
		:ObserveChanges()
	local startTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("StartTweenConfiguration"), Config.TWEEN_CONFIG)
		:ObserveChanges()
	local endTweenConfiguration =
		Config.GetConfig(scope, boosterConfig:FindFirstChild("EndTweenConfiguration"), Config.TWEEN_CONFIG)
		:ObserveChanges()

	local extraVariableConfig = boosterConfig:FindFirstChild("ExtraVariables")
	local extraVariables = if extraVariableConfig
		then extraVariableConfig:GetAttributes()
		else {}

	--> Functions
	local function getBoostData(booster: Booster): CharacterManager_Types.BoostData?
		local boostModule = CharacterUtil.getBoostModule(booster.configuration.Type)
		if not boostModule then
			return nil
		end

		return {
			startTime = os.clock(),

			mode = booster.configuration.Mode,
			type = booster.configuration.Type,
			power = booster.configuration.Power,
			duration = booster.configuration.Duration,
			timerDecimals = booster.configuration.TimerDecimals,
			hideGUI = booster.configuration.HideGUI,
			startTweenInfo = TweenInfo.new(
				booster.startTweenConfig.Time,
				booster.startTweenConfig.Style,
				booster.startTweenConfig.Direction
			),
			endTweenInfo = TweenInfo.new(
				booster.endTweenConfig.Time,
				booster.endTweenConfig.Style,
				booster.endTweenConfig.Direction
			),

			module = boostModule,
			extraVariables = booster.extraVariables,

			-- these will get filled in later, required to be placeholders here
			-- due to type checker
			infinite = false,
			multiplier = 1,
			timeLeft = 0,
		}
	end

	--> Cache system and main loop for zone boosters
	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache: BoosterCache = {
			activators = {},
			boosters = {},
			activeBoosters = {},
		}

		local overlapParams = OverlapParams.new()
		overlapParams.CollisionGroup = ""
		overlapParams.ExcludeInstances = {CharacterUtil.getCharacter().character :: Instance}
		local characterHitboxParts = CharacterUtil.getHitbox("StaticWholeBody")
		
		scope:add(player.CharacterAdded:Connect(function(char: Model)
			char:WaitForChild("_HITBOX")
			overlapParams.ExcludeInstances = {char :: Instance}
			characterHitboxParts = CharacterUtil.getHitbox("StaticWholeBody")
		end))

		local lastTick = os.clock()
		local fpsCap = 1 / 60
		
		scope.rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			--> Cap loop to 60fps
			local currentTick = os.clock()
			if currentTick - lastTick < fpsCap then
				return
			end
			lastTick = currentTick
			
			if not cache.boosters[1] then
				return
			end
			
			debug.profilebegin("Booster -> Update")

			--> Get touching parts and determine if any zone boosters are being touched
			local touchingParts = {}
			for _, hitboxPart in characterHitboxParts do
				for _, part in Workspace:GetPartsInPart(hitboxPart, overlapParams) do
					touchingParts[part] = true
				end
			end

			local touchingBoosters: { Booster } = {}
			for _, booster in cache.boosters do
				if
					touchingParts[booster.hitbox]
				then
					table.insert(touchingBoosters, booster)
				end
			end

			--> Activate boost if touching
			local boostTypesFound = {}

			for _, touchedBooster in touchingBoosters do
				boostTypesFound[touchedBooster.configuration.Type] = true

				local activeBooster = cache.activeBoosters[touchedBooster.configuration.Type]
				if activeBooster and activeBooster.id ~= touchedBooster.id or not activeBooster then
					cache.activeBoosters[touchedBooster.configuration.Type] = touchedBooster

					local boostData = getBoostData(touchedBooster)
					if boostData then
						CharacterUtil.startBoost(boostData)
					end
				end
			end

			--> If not touching, deactivate boost
			for boostType, activeBooster in cache.activeBoosters do
				if activeBooster and not boostTypesFound[boostType] then
					cache.activeBoosters[boostType] = nil

					local activeBoost = CharacterUtil.getActiveBoost(boostType, activeBooster.configuration.Mode)
					if activeBoost then
						CharacterUtil.removeBoost(activeBoost)
					end
				end
			end

			debug.profileend()
		end))

		SequencerSupport(scope.rootScope, utility, cache)
		return cache
	end)

	--> Setting up this booster now
	scope:attach(booster)

	--> Check for problems
	if not configuration.Mode then
		scope:log({
			"Booster has an unknown Mode and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end

	if not configuration.Type then
		scope:log({
			"Booster has an unknown Type and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Main functionality
	local boosterData: Booster = {
		hitbox = booster,
		configuration = configuration,
		extraVariables = extraVariables,
		startTweenConfig = startTweenConfiguration,
		endTweenConfig = endTweenConfiguration,
		id = HttpService:GenerateGUID(),
	}

	if configuration.Mode == "Default" then
		local function activateBoost()
			if booster:GetAttribute("Activated") == false then
				return
			end

			local boostData = getBoostData(boosterData)
			if boostData then
				CharacterUtil.startBoost(boostData)
			end
		end
		cache.activators[booster] = activateBoost
		scope:add(function()
			cache.activators[booster] = nil
		end)

		scope:add(booster.Touched:Connect(function(toucher)
			if not utility.ClientObjects.evaluateToucher(booster, toucher, touchConfiguration) then
				return
			end

			activateBoost()
		end))

		if touchConfiguration.canFlip then
			scope:add(utility.ClientObjects.bindToFlip(booster, activateBoost))
		end
	elseif configuration.Mode == "Pad" then
		local padHitbox = Instance.fromExisting(booster)
		padHitbox.Name = "Hitbox"
		padHitbox.Transparency = 1
		padHitbox.CanCollide = false
		padHitbox.CanTouch = true
		padHitbox.CanQuery = true
		padHitbox.Massless = true
		padHitbox.Size = Vector3.new(booster.Size.X, math.abs(configuration.PadDistance), booster.Size.Z)
		padHitbox.CFrame = booster.CFrame * CFrame.new(0, (configuration.PadDistance * 0.5) + (booster.Size.Y * 0.5), 0)

		padHitbox:AddTag("Invisible")
		padHitbox:AddTag("IgnoreCanCollide")

		local padWeld = Instance.new("WeldConstraint")
		padWeld.Part0 = booster
		padWeld.Part1 = padHitbox
		padWeld.Parent = padHitbox
		padHitbox.Parent = booster
		padHitbox.Anchored = false

		boosterData.hitbox = padHitbox
	elseif configuration.Mode ~= "Zone" then
		scope:log({
			"Booster has an unknown Mode and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end
	
	if configuration.Mode ~= "Default" then
		if ClientObjectUtil.isInstanceActive(scope, boosterData.hitbox) then
			table.insert(cache.boosters, boosterData)
		end
		
		ClientObjectUtil.listenInstanceActive(scope, boosterData.hitbox, nil, function(active)
			if active then
				if table.find(cache.boosters, boosterData) then
					return
				end
				table.insert(cache.boosters, boosterData)
			else
				local boosterDataSlot = table.find(cache.boosters, boosterData)
				if boosterDataSlot then
					table.remove(cache.boosters, boosterDataSlot)
				end
			end
		end)
	end

	scope:add(function()
		local boosterDataSlot = table.find(cache.boosters, boosterData)
		if boosterDataSlot then
			table.remove(cache.boosters, boosterDataSlot)
		end
	end)
end

return Booster
