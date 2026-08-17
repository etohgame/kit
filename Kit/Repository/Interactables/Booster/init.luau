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
	RunOnStart = true,
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

function Booster.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local boosterConfig = scope.instance
	if not boosterConfig then
		local repo = scope.rootScope.repository
		if not repo["Interactables/BoostPad"] then
			repo["Interactables/BoostPad"] = Booster
		end
		return
	end

	local booster = boosterConfig.Parent
	if not booster or not booster:IsA("BasePart") then
		return
	end
	
	--> BoostPad backwards compatibility
	if scope.scriptPath == "Interactables/BoostPad" then
		scope:log({
			"BoostPads have been deprecated in favor of the new Pad mode on regular Boosters.",
			"Please convert your old BoostPads into regular Boosters.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		
		local startTweenConfig = scope:add(Instance.new("Configuration"))
		startTweenConfig.Parent = boosterConfig
		startTweenConfig.Name = "StartTweenConfiguration"
		startTweenConfig:SetAttribute("Time", 0)
		startTweenConfig:SetAttribute("Direction", Enum.EasingDirection.In)
		startTweenConfig:SetAttribute("Style", Enum.EasingStyle.Linear)
		
		local endTweenConfig = scope:add(Instance.new("Configuration"))
		endTweenConfig.Parent = boosterConfig
		endTweenConfig.Name = "EndTweenConfiguration"
		endTweenConfig:SetAttribute("Time", 0)
		endTweenConfig:SetAttribute("Direction", Enum.EasingDirection.In)
		endTweenConfig:SetAttribute("Style", Enum.EasingStyle.Linear)
		
		boosterConfig:SetAttribute("Mode", "Pad")
		boosterConfig:SetAttribute("PadDistance", boosterConfig:GetAttribute("Distance"))
		scope:add(boosterConfig:GetAttributeChangedSignal("Distance"):Connect(function()
			boosterConfig:SetAttribute("PadDistance", boosterConfig:GetAttribute("Distance"))
		end))
	end

	local CharacterUtil = utility.Character
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
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.CollisionGroup = ""
	CharacterUtil.getHitbox("StaticWholeBody", overlapParams)

	local cache = utility.Scope.getCached(scope, scope.scriptPath, function()
		local cache: BoosterCache = {
			activators = {},
			boosters = {},
			activeBoosters = {},
		}

		local lastTick = os.clock()
		local fpsCap = 1 / 60

		local isTableEmpty = utility.Table.IsEmpty
		scope.rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			debug.profilebegin("Booster -> Update")
			if isTableEmpty(cache.boosters) then
				return
			end

			--> Cap loop to 60fps
			local currentTick = os.clock()
			if currentTick - lastTick < fpsCap then
				return
			end
			lastTick = currentTick

			--> Get touching parts and determine if any zone boosters are being touched
			local touchingBoosters: { Booster } = {}
			for _, booster in cache.boosters do
				if
					#Workspace:GetPartsInPart(booster.hitbox, overlapParams) > 0
					and booster.hitbox:GetAttribute("Activated") ~= false
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
	elseif configuration.Mode == "Zone" then
		table.insert(cache.boosters, boosterData)
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
		table.insert(cache.boosters, boosterData)
	else
		scope:log({
			"Booster has an unknown Mode and cannot function.",
			`Path: {booster:GetFullName()}`,
			type = "warn",
		})
		return
	end
end

return Booster
