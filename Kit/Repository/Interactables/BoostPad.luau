--!strict
--!optimize 2
--@version boostpad-6.1.0
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

-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!
-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!
-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!

-- boost pads have been deprecated in 6.1.0 in favor of merging it's
-- functionality into the main booster object. this script will remain as there
-- are still towers that use it, however please be aware that it will no longer
-- be maintained. any bugs with legacy boost pads will NOT be fixed and you
-- should convert them to regular boosters if you want to use them

-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!
-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!
-- !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!! IMPORTANT WARNING !!!

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local CharacterManager_Types = require(ReplicatedStorage.Framework.Kit.Managers.CharacterManager.TypeDefs)

local BoostPad = {
	CanQueue = true,
	RunOnStart = false,
}

local FPS_CAP = 1 / 60

local PAD_CONFIG_TEMPLATE
function BoostPad.Init(utility: _T.Utility)
	local Config = utility.Config
	PAD_CONFIG_TEMPLATE = {
		Type = "Unknown",
		Distance = 10,
		Power = 50,
		HideGUI = false,
	}
end

type BoostPad = {
	pad: BasePart,
	hitbox: BasePart,
	configuration: { [string]: any },
	id: string,
	touching: boolean,
}

type BoostPadCache = {
	boostPads: { BoostPad },
	activePads: { [string]: BoostPad? },
}

function BoostPad.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local boostPadConfig = scope.instance
	if not boostPadConfig then
		return
	end

	local boostPad = boostPadConfig.Parent
	if not boostPad or not boostPad:IsA("BasePart") then
		return
	end

	scope:log({
		"BoostPads have been deprecated in favor of the new Pad mode on regular Boosters.",
		"Please convert your old BoostPads into regular Boosters.",
		`Path: {boostPad:GetFullName()}`,
		type = "warn",
	})

	local CharacterUtil = utility.Character
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, boostPadConfig, PAD_CONFIG_TEMPLATE):ObserveChanges()

	--> Cache system and main loop
	local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
		local cache: BoostPadCache = {
			boostPads = {},
			activePads = {},
		}

		local function getBoostData(boostPad: BoostPad): CharacterManager_Types.BoostData
			local boostModule =
				CharacterUtil.getBoostModule(boostPad.configuration.Type) :: CharacterManager_Types.Boost

			return {
				type = boostPad.configuration.Type,
				power = boostPad.configuration.Power,
				hideGUI = boostPad.configuration.HideGUI,

				module = boostModule,

				-- everything below is not used in boost pads but they have to
				-- be here as placeholders to avoid type errors
				startTime = 0,
				mode = "Pad",
				duration = 0,
				timerDecimals = 0,
				startTweenInfo = TweenInfo.new(),
				endTweenInfo = TweenInfo.new(),
				infinite = false,
				multiplier = 0,
				timeLeft = 0,
			}
		end

		--> Get Hitbox
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.CollisionGroup = ""
		utility.Character.getHitbox("StaticCenter", overlapParams)
		rootScope:add(Players.LocalPlayer.CharacterAdded:Connect(function(character)
			task.wait()
			overlapParams.FilterDescendantsInstances = {}
			utility.Character.getHitbox("StaticCenter", overlapParams)
		end))

		--> Loop
		local lastTick = os.clock()
		local CharacterUtil = utility.Character
		local isTableEmpty = utility.Table.IsEmpty
		rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			debug.profilebegin("BoostPads -> Update")

			if isTableEmpty(cache.boostPads) then
				return
			end

			--> Cap loop to 60fps
			local currentTick = os.clock()
			if currentTick - lastTick < FPS_CAP then
				return
			end
			lastTick = currentTick

			--> Get touching parts and determine if a boost pad is being touched
			local touchingPads: { BoostPad } = {}
			for _, boostPad in cache.boostPads do
				if
					boostPad.touching
					and boostPad.pad:GetAttribute("Activated") ~= false
					and #Workspace:GetPartsInPart(boostPad.hitbox, overlapParams) > 0
				then
					table.insert(touchingPads, boostPad)
				elseif boostPad.touching then
					-- checks above failed and the touching variable is still true
					boostPad.touching = false
				end
			end

			--> Activate boost if touching
			local boostTypesFound = {}
			for _, pad in touchingPads do
				boostTypesFound[pad.configuration.Type] = true

				local activePad = cache.activePads[pad.configuration.Type]
				if activePad and activePad.id ~= pad.id or not activePad then
					local existingBoost = CharacterUtil.getActiveBoost(pad.configuration.Type, "Pad")
					if existingBoost then
						CharacterUtil.removeBoost(existingBoost)
					end

					cache.activePads[pad.configuration.Type] = pad
					local boostData = getBoostData(pad)
					CharacterUtil.startBoost(boostData)
				end
			end

			--> If not touching, deactivate boost
			for boostType, pad in cache.activePads do
				if pad and not boostTypesFound[boostType] then
					cache.activePads[boostType] = nil

					local activeBoost = CharacterUtil.getActiveBoost(boostType, "Pad")
					if activeBoost then
						CharacterUtil.removeBoost(activeBoost)
					end
				end
			end

			debug.profileend()
		end))

		return cache
	end

	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)

	--> setting up this boost pad now
	scope:attach(boostPad)

	-- check for problems
	local testBoostData = CharacterUtil.getBoostModule(configuration.Type)
	if not configuration.Type or not testBoostData then
		scope:log({
			"BoostPad has an unknown Type and cannot function.",
			`Path: {boostPad:GetFullName()}`,
			type = "warn",
		})
		return
	end

	-- create a hitbox based on the configured distance
	local boostPadHitbox = Instance.fromExisting(boostPad)
	boostPadHitbox.Name = "Hitbox"
	boostPadHitbox.Transparency = 1
	boostPadHitbox.CanCollide = false
	boostPadHitbox.CanTouch = true
	boostPadHitbox.CanQuery = true
	boostPadHitbox.Massless = true
	boostPadHitbox.Size = Vector3.new(boostPad.Size.X, math.abs(configuration.Distance), boostPad.Size.Z)
	boostPadHitbox.CFrame = boostPad.CFrame * CFrame.new(0, (configuration.Distance * 0.5) + (boostPad.Size.Y * 0.5), 0)

	local boostPadWeld = Instance.new("WeldConstraint")
	boostPadWeld.Part0 = boostPad
	boostPadWeld.Part1 = boostPadHitbox
	boostPadWeld.Parent = boostPadHitbox
	boostPadHitbox.Parent = boostPad
	boostPadHitbox.Anchored = false

	-- add to the boost pad list
	local boostPadData: BoostPad = {
		pad = boostPad,
		hitbox = boostPadHitbox,
		configuration = configuration,
		id = HttpService:GenerateGUID(),
		touching = false,
	}

	table.insert(cache.boostPads, boostPadData)
	scope:add(boostPadHitbox.Touched:Connect(function(touchingPart)
		if not utility.ClientObjects.validatePlayerToucher(touchingPart, "StaticCenter") then
			return
		end
		boostPadData.touching = true
	end))

	scope:add(function()
		local index = table.find(cache.boostPads, boostPadData)
		if index then
			table.remove(cache.boostPads, index)
		end
	end)
end

return BoostPad
