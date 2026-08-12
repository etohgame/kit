--!strict
--!optimize 2
-- By @synnwave, Camille (09/12/24 DD/MM/YY)

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

--[=[
	@class CharacterManager
	@client
	
	Manager module for character-related things such as collisions, damage
	bricks, and boosts.
]=]

--[[
---------------------------------------------------------------------------
Services, modules and other objects
---------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Framework = ReplicatedStorage.Framework

local Log = require(Framework.Log)

local PropertyUtil = require(Framework.Kit.Utility.Property)
local Config = require(Framework.Kit.Utility.Config)
local GuiManager = require(Framework.Kit.Managers.GuiManager)
local _TDefs = require(script.TypeDefs)

local DamageEvent = Framework.Remotes.Towers.Objects.DamageEvent

--[[
---------------------------------------------------------------------------
Collision constants
---------------------------------------------------------------------------
]]

local LOCAL_PLAYER_COLLISIONGROUP = "Player"
local OTHER_PLAYER_COLLISIONGROUP = "OtherPlayers"

--[[
---------------------------------------------------------------------------
Damage brick constant
---------------------------------------------------------------------------
]]

local VALID_DAMAGEBRICKS = table.freeze({
	kills = 5,
	double = 10,
	ouch = 20,
	instakills = math.huge,
	custom = 0, -- custom value; you can make this a number attribute
	heals = "Heals",
} :: _TDefs.__VALID_DAMAGEBRICKS)

--[[
---------------------------------------------------------------------------
Boost variables
---------------------------------------------------------------------------
]]

local activeBoosts: { _TDefs.BoostData } = {}
local boostModules: {[string]: _TDefs.Boost} = {}
local customBoostModules: {[string]: _TDefs.Boost} = {}
local boostID = 0

local humanoidTweens: {[string]: Tween} = {}

local BOOST_TIMER_LARGE_DURATION = 10 ^ 10
local BOOST_INFINITE_DURATION = math.huge

local damageCooldown = {} :: { [BasePart]: boolean }

--[[
---------------------------------------------------------------------------
Main table
---------------------------------------------------------------------------
]]

local CharacterManager = {
	__initialized = false,
	VALID_DAMAGEBRICKS = VALID_DAMAGEBRICKS,
} :: _TDefs.CharacterManager

--[[
---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------
]]

--[=[
	@within CharacterManager
	
	Function internally used to validate a damage brick's damage value.
	This also checks whether the damage brick is deactivated or not.
]=]
function CharacterManager:ValidateDamageBrick(brick: BasePart)
	local damageAmount: (number | string)?
	if brick:GetAttribute("Activated") == false then
		return
	end

	local configuration = brick:FindFirstChild("DamageBrickConfiguration")
	local typeString = PropertyUtil.assureAttribute(configuration, "Type", "")
	local cooldown = PropertyUtil.assureAttribute(configuration, "Cooldown", 0)

	for identifier, value in VALID_DAMAGEBRICKS do
		if identifier == "custom" and typeString == identifier then
			damageAmount = PropertyUtil.assureAttribute(configuration, "Damage", 0)
			break
		end

		if typeString == identifier or brick:FindFirstChild(identifier) then
			damageAmount = value
			break
		end
	end

	return damageAmount, cooldown
end

--[=[
	@within CharacterManager
	
	Fires the DamageEvent with the given `damage` value.
	`damage` can be either a `number`, or a `string` representing a key in the
	`VALID_DAMAGEBRICKS` table.
]=]
function CharacterManager:Damage(damage: BasePart | string | number)
	if not self.__initialized or (typeof(damage) == "Instance" and damageCooldown[damage]) then
		return
	end

	local cooldown = 0
	local damageAmount: (number | string)?
	if typeof(damage) == "Instance" and damage:IsA("BasePart") then
		damageAmount, cooldown = CharacterManager:ValidateDamageBrick(damage)
	elseif typeof(damage) == "number" then
		damageAmount = damage
	end

	if not damageAmount then
		return
	end
	if cooldown > 0 and typeof(damage) == "Instance" then
		damageCooldown[damage] = true
		task.delay(cooldown, function()
			damageCooldown[damage] = false
		end)
	end

	DamageEvent:FireServer(damageAmount)
end

--[=[
	@within CharacterManager
	
	Returns the `player`'s `Humanoid` if it exists.
]=]
function CharacterManager:GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return
	end

	return character:FindFirstChildOfClass("Humanoid")
end

--[=[
	@within CharacterManager
	
	Changes the given `property` on the Humanoid to the given `value`.
	A `TweenInfo` can be provided to tween the value.
]=]
function CharacterManager:ChangeHumanoidProperty(property: string, value: any, tweenInfo: TweenInfo?)
	local humanoid = CharacterManager:GetHumanoid(Players.LocalPlayer)
	if not humanoid then
		return
	end

	if humanoidTweens[property] then
		humanoidTweens[property]:Cancel()
	end

	if tweenInfo and tweenInfo.Time > 0 then
		local tween = TweenService:Create(humanoid, tweenInfo, {[property] = value})
		tween:Play()
		tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				tween:Destroy()
				humanoidTweens[property] = nil
			end
		end)

		humanoidTweens[property] = tween
	else
		PropertyUtil.setPropertySafe(humanoid, property, value)
	end
end

--[=[
	@within CharacterManager
	
	Get a currently active boost with the given `boostType`.
	`boostMode` can be optionally included to only look for boosters of that mode.
]=]
function CharacterManager:GetActiveBoost(boostType: string, boostMode: string?): _TDefs.BoostData?
	-- look for the most recently started boost
	local chosenBoost: _TDefs.BoostData? = nil
	local boostPriority = 0

	for _, boost in activeBoosts do
		if
			boost.type == boostType
			and (boost.mode == boostMode or not boostMode)
			and (boost.priority and boost.priority > boostPriority)
		then
			boostPriority = boost.priority
			chosenBoost = boost
		end
	end

	return chosenBoost
end

--[=[
	@within CharacterManager
	
	Returns whether a given boost should be infinite or not. Boosts with a duration
	of 0 or below, or higher than 10^10 are considered infinite and
	will never run out unless removed by a boost remover.
]=]
function CharacterManager:IsBoostInfinite(boostData: _TDefs.BoostData): boolean
	return boostData.duration <= 0 or boostData.duration >= BOOST_TIMER_LARGE_DURATION
end

--[=[
	@within CharacterManager
	
	Gets the boost module for the specified boost type.
]=]
function CharacterManager:GetBoostModule(boostType: string): _TDefs.Boost?
	return boostModules[boostType] or customBoostModules[boostType]
end

--[=[
	@within CharacterManager
	
	Registers a custom boost with the given type and data.
	After registering, custom boosts can be used in Boosters.
	Custom boosts will be unregistered when the character respawns.
]=]
function CharacterManager:RegisterCustomBoost(boostType: string, boostData: _TDefs.Boost)
	if
		not boostData.Information
		or typeof(boostData.Start) ~= "function"
		or typeof(boostData.Update) ~= "function"
		or typeof(boostData.End) ~= "function"
		or typeof(boostData.GetMultiplier) ~= "function"
	then
		Log({
			`Custom boost {boostType} is malformed and can not be registered`,
			type = "warn",
		})
		return
	end

	customBoostModules[boostType] = boostData
end

--[=[
	@within CharacterManager
	
	Starts a boost with the given boost data.
	If a boost with the given type is already active, the already active boost will be
	refreshed instead of a new boost being started.
]=]
function CharacterManager:StartBoost(boostData: _TDefs.BoostData)
	-- if a boost of this type is already active, refresh it instead of starting a new one
	local activeBoost = CharacterManager:GetActiveBoost(boostData.type, boostData.mode)
	if activeBoost then
		activeBoost.power = boostData.power
		activeBoost.startTime = os.clock()
		activeBoost.duration = boostData.duration
		activeBoost.timerDecimals = boostData.timerDecimals
		activeBoost.startTweenInfo = boostData.startTweenInfo
		activeBoost.endTweenInfo = boostData.endTweenInfo
		activeBoost.infinite = CharacterManager:IsBoostInfinite(boostData)
		activeBoost.multiplier = activeBoost.module.GetMultiplier(activeBoost)
		activeBoost.timeLeft = boostData.duration

		activeBoost.module.Update(boostData)
		GuiManager:UpdateBoostFrame(activeBoost)
		return
	end

	boostID += 1
	boostData.priority = boostID

	boostData.multiplier = boostData.module.GetMultiplier(boostData)
	boostData.frame = GuiManager:CreateBoostFrame(boostData)
	table.insert(activeBoosts, boostData)
	boostData.module.Start(boostData)
	boostData.module.Update(boostData)

	if boostData.mode == "Default" then --handle regular boosters
		boostData.infinite = CharacterManager:IsBoostInfinite(boostData)

		local boostLoop
		boostLoop = RunService.Heartbeat:Connect(function()
			local activeBoostData = CharacterManager:GetActiveBoost(boostData.type, boostData.mode)

			-- if the boost data can't be found (ended by a remover), cancel the loop
			if not activeBoostData then
				boostLoop:Disconnect()
				return
			end

			-- update the boost timer
			local timePassed = os.clock() - activeBoostData.startTime
			activeBoostData.timeLeft = if boostData.infinite
				then BOOST_INFINITE_DURATION
				else math.max(0, activeBoostData.duration - timePassed)

			GuiManager:UpdateBoostFrame(activeBoostData)

			-- if time is up, end the boost
			if activeBoostData.timeLeft <= 0 then
				boostLoop:Disconnect()
				CharacterManager:RemoveBoost(boostData)
				return
			end
		end)
	end
end

--[=[
	@within CharacterManager
	
	Ends the given boost.
]=]
function CharacterManager:RemoveBoost(boostData: _TDefs.BoostData)
	local boostIndex = table.find(activeBoosts, boostData)
	if boostIndex then
		table.remove(activeBoosts, boostIndex)
		GuiManager:DestroyBoostFrame(boostData)
		boostData.module.End(boostData)
	end
end

--[=[
	@within CharacterManager
	
	Returns a table containing the currently active boosts.
]=]
function CharacterManager:GetActiveBoosts(): { _TDefs.BoostData }
	return activeBoosts
end

function CharacterManager:Init()
	local localPlayer = Players.LocalPlayer
	if self.__initialized or not localPlayer then
		return CharacterManager
	end
	self.__initialized = true

	-- require boost modules
	for _, boost in script.Boosts:GetChildren() do
		if boost:IsA("ModuleScript") then
			boostModules[boost.Name] = require(boost) :: _TDefs.Boost
		end
	end

	local function setupLocalPlayer(player: Player, character: Model)
		-- reset active boosts
		for _, boost in activeBoosts do
			GuiManager:DestroyBoostFrame(boost)
		end

		table.clear(activeBoosts)
		table.clear(customBoostModules)
		
		local humanoid = character:WaitForChild("Humanoid")
		
		do -- New TouchScript implementation
			if not humanoid:IsA("Humanoid") then
				return
			end
			humanoid.Touched:Connect(function(touchingPart, hitPart)
				if humanoid.Health <= 0 then
					return
				end
				self:Damage(touchingPart)
			end)
		end
		
		do -- Enable Physics Fix (Truss Fix + Head Collision Glitch Fix)
			local fixScript = script.PhysicsFixer:Clone()
			fixScript.Parent = character
			fixScript.Enabled = true
		end
		
		do -- Static Hitbox for client objects
			if not humanoid.RootPart then
				return
			end
			local hitbox = script._HITBOX:Clone()
			hitbox:PivotTo(humanoid.RootPart:GetPivot())
			hitbox.RootPart.WeldConstraint.Part1 = humanoid.RootPart
			hitbox.RootPart.Anchored = false
			hitbox.Parent = character
		end
	end

	local function onPlayerAdded(player: Player)
		local isLocalPlayer = player == localPlayer
		local currentCollisionGroup = if isLocalPlayer then LOCAL_PLAYER_COLLISIONGROUP else OTHER_PLAYER_COLLISIONGROUP

		local function onCharacterAdded(character: Model)
			if not character then
				return
			end

			task.wait()
			for _, part in character:GetChildren() do
				if not part:IsA("BasePart") then
					continue
				end
				part.CollisionGroup = currentCollisionGroup
			end

			character.ChildAdded:Connect(function(part)
				if not part:IsA("BasePart") then
					return
				end
				part.CollisionGroup = currentCollisionGroup
			end)

			-- moved this into a seperate function for cleanliness
			if isLocalPlayer then
				setupLocalPlayer(player, character)
			end
		end

		pcall(onCharacterAdded, player.Character or player.CharacterAdded:Wait())
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	-- Initialize players
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	return CharacterManager
end

return CharacterManager
