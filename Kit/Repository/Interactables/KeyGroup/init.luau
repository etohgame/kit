--!strict
--!optimize 2
--@version keygroup-6.0.1
--@creator synnwave
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
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local TRAIL_UPDATE_THRESHOLD = 0.75
local TRAIL_LOG_LIMIT = 100
local TRAIL_DISTANCE = 6
local LERP_SPEED = 15
local MAX_PIVOT_DISTANCE = 150
local RADIANS_PER_SECOND = 180 / math.pi
local RANDOM = Random.new()
local DOOR_DESTROY_METHODS = {
	vanish = function(part: BasePart)
		part.CanCollide = false
		part.CanTouch = false
		local tween = TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { Transparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			part:Destroy()
			tween:Destroy()
			tween = nil
		end)
	end,

	fall = function(part: BasePart)
		local powerMultiplier = part:GetAttribute("FallPower")
		if typeof(powerMultiplier) ~= "number" then
			powerMultiplier = 1
		end

		part.Archivable = false
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.AssemblyAngularVelocity = RANDOM:NextUnitVector() * powerMultiplier
		part.AssemblyLinearVelocity = RANDOM:NextUnitVector() * (3 * powerMultiplier)
		for _, joint in part:GetJoints() do -- BreakJoints is deprecated
			joint:Destroy()
		end
		
		task.delay(10, function()
			part:Destroy()
		end)
	end,

	destroy = function(part: BasePart)
		part:Destroy()
	end,
}

local KeyGroup = {
	CanQueue = true,
	RunOnStart = false,
}

local KEY_CONFIG_TEMPLATE = {
	SpinSpeed = 5,
	Timer = 0,
	TimerDecimalPlaces = 1,
	ViewportOffset = CFrame.identity,
	TimerText = "{T}",
}
local DOOR_CONFIG_TEMPLATE = {
	RequiredKeys = 1,
}

local _TDefs = require(script.TypeDefs)
type Key = _TDefs.Key
type KeyDoor = _TDefs.KeyDoor
type KeyGroup = _TDefs.KeyGroup
type Cache = _TDefs.Cache

local function handleKeyCache(rootScope: _T.Scope, utility: _T.Utility): Cache
	local generateUID = utility.Functions.generateUID

	local cache = {
		groups = {},
		keys = {},
		doors = {},
		activeKeys = {},
		id = generateUID(),
	} :: Cache

	--> Key functions
	local random = Random.new()
	local function collectKey(self: Key)
		local keyData = assert(self.__private)
		if keyData.active or keyData.cooldown or keyData.used or not self.instance then
			return
		end

		keyData.active = true
		table.insert(cache.activeKeys, keyData.id)
		if self.config.Timer > 0 then
			keyData.startTimer = os.clock()
			self.timerBillboard.Enabled = true
		end

		-- VFX & SFX
		local emitter = Instance.fromExisting(self.hitbox)
		emitter.Transparency = 1
		emitter.CanCollide = false
		emitter.CanTouch = false
		emitter.Anchored = true
		emitter.Parent = Workspace
		emitter:PivotTo(self.hitbox:GetPivot())

		local particle = self.hitbox:FindFirstChild("ReplaceEffect")
		if not particle or not particle:IsA("ParticleEmitter") then
			particle = script.Effect:Clone()
		end
		if particle:IsA("ParticleEmitter") then
			particle.Parent = emitter
			particle.Rate = 0

			local emitCount = particle:GetAttribute("EmitCount") or NumberRange.new(20, 50)
			if typeof(emitCount) == "NumberRange" then
				emitCount = random:NextInteger(emitCount.Min, emitCount.Max)
			elseif typeof(emitCount) ~= "number" then
				emitCount = 10
			end

			particle:Emit(emitCount)
			task.delay(particle.Lifetime.Max / particle.TimeScale, function()
				emitter:Destroy()
			end)
		end

		utility.Functions.playSoundFromInstance(self.hitbox, self.hitbox, "ReplaceSound", script.PickupSound)
	end

	local function returnKey(self: Key)
		local keyData = assert(self.__private)
		if (not keyData.active) or keyData.cooldown or not self.instance then
			return
		end

		local keyIndex = table.find(cache.activeKeys, keyData.id)
		if not keyIndex then
			return
		end

		table.remove(cache.activeKeys, keyIndex)
		keyData.startTimer = nil
		keyData.active = false
		keyData.cooldown = true
		self.timerBillboard.Enabled = false
		task.delay(1, function()
			keyData.cooldown = false
		end)
	end

	local function keyConstructor(group: KeyGroup, key: Key): Key?
		if not key.instance or not key.instance.Parent then
			return
		end

		local id = generateUID()
		local cacheData = {
			id = id,
			groupID = group.id,
			active = false,
			cooldown = false,
			used = false,
			isViewportDisplayed = false,
			parent = key.instance.Parent,
			viewport = group.scope:add(script.KeyViewport:Clone()),
			collectKey = collectKey,
			returnKey = returnKey,
			group = group,
		}
		key.__private = cacheData

		for _, part in key.instance:GetDescendants() do
			if part:IsA("BasePart") and part ~= key.hitbox then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.CollisionGroup = "NeverCollide"
			end
		end

		group.keys[id] = key
		cache.keys[id] = key
		return key
	end

	--> Key door functions
	local function updateSigns(self: KeyDoor)
		local doorData = assert(self.__private)

		local requiredKeys = self.config.RequiredKeys
		local keysUsed = #doorData.usedKeys
		local keysLeft = requiredKeys - keysUsed
		local keysLeftRemainder = if keysLeft == 1 then "" else "s"
		local keysRequiredRemainder = if requiredKeys == 1 then "" else "s"
		local keysUsedRemainder = if keysUsed == 1 then "" else "s"
		for label, pattern in self.doorSigns do
			label.Text = pattern
				:gsub("{R}", tostring(requiredKeys))
				:gsub("{U}", tostring(keysUsed))
				:gsub("{L}", tostring(keysLeft))
				:gsub("{RS}", keysRequiredRemainder)
				:gsub("{US}", keysUsedRemainder)
				:gsub("{LS}", keysLeftRemainder)
		end
	end

	local function unlockDoor(self: KeyDoor)
		local doorData = assert(self.__private)
		if doorData.unlocked or #doorData.usedKeys < self.config.RequiredKeys then
			return
		end

		doorData.unlocked = true
		self.hitbox.CanTouch = false
		updateSigns(self)
		utility.Functions.playSoundFromInstance(self.hitbox, self.hitbox, "ReplaceSound", script.UnlockSound)

		for part, destroyType in self.doorParts do
			local destroyFunction = DOOR_DESTROY_METHODS[destroyType]
			if destroyFunction then
				task.spawn(destroyFunction, part)
			end
		end
	end

	local function useKey(self: KeyDoor, keyId: string)
		local doorData = assert(self.__private)
		if doorData.unlocked then
			return
		end

		local key = doorData.group.keys[keyId]
		if not key or not key.__private then
			return
		end
		local keyData = key.__private
		if (not keyData.active) or keyData.used then
			return
		end

		key.hitbox.CanTouch = false
		keyData.used = true
		keyData.returnKey(key)
		key.config.SpinSpeed = 0
		keyData.targetCFrame = self.hitbox:GetPivot()
		table.insert(doorData.usedKeys, keyId)

		task.delay(0.4, function()
			if not key.instance then
				return
			end
			key.instance:Destroy()
			key.instance = nil
		end)
		if #doorData.usedKeys >= self.config.RequiredKeys then
			doorData.unlockDoor(self)
		else
			utility.Functions.playSoundFromInstance(self.hitbox, self.hitbox, "ReplaceSound", script.UnlockSound)
		end

		updateSigns(self)
	end

	local function doorConstructor(group: KeyGroup, door: KeyDoor): KeyDoor?
		local id = generateUID()
		local cacheData = {
			id = id,
			groupID = group.id,
			usedKeys = {},
			unlocked = false,
			unlockDoor = unlockDoor,
			useKey = useKey,
			group = group,
			updateSigns = updateSigns,
		}
		door.__private = cacheData

		group.doors[id] = door
		cache.doors[id] = door
		updateSigns(door)
		return door
	end

	--> Group functions
	local function groupConstructor(scope: _T.Scope): KeyGroup
		local id = generateUID()
		local group: KeyGroup = {
			scope = scope,
			id = id,
			keys = {},
			doors = {},
			addKey = keyConstructor,
			addDoor = doorConstructor,
		}

		cache.groups[id] = group
		scope:add(function()
			cache.groups[id] = nil
			for _, key in group.keys do
				local keyData = key.__private
				if keyData then
					keyData.returnKey(key :: Key)
					cache.keys[keyData.id] = nil
				end
			end
			for _, door in group.doors do
				local doorData = door.__private
				if doorData then
					cache.doors[doorData.id] = nil
				end
			end
			group = nil :: any
		end)

		return group
	end

	cache.newGroup = groupConstructor

	--> Render Loop
	local trailList: { Vector3 } = table.create(TRAIL_LOG_LIMIT, Vector3.zero)
	local lastTrailUpdatePosition: Vector3? = nil
	local lastTrailUpdateTime = 0

	local characterInstances = utility.Character.getCharacter()
	local currentCamera = Workspace.CurrentCamera
	local formatTimer = utility.ClientObjects.formatTimerText
	rootScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
		debug.profilebegin("KeyGroup > Loop")

		local rootPart = characterInstances.rootPart
		if not rootPart then
			debug.profileend()
			return
		end

		local currentClock = os.clock()
		local cameraPosition = currentCamera.CFrame.Position

		debug.profilebegin("KeyGroup > Loop > Key Trail Logging")
		local currentPosition = rootPart.Position
		if
			(#cache.activeKeys <= 0 and (currentClock - lastTrailUpdateTime) > TRAIL_UPDATE_THRESHOLD)
			or (
				not lastTrailUpdatePosition
				or (currentPosition - lastTrailUpdatePosition).Magnitude > TRAIL_UPDATE_THRESHOLD
			)
		then
			table.insert(trailList, 1, currentPosition)
			if #trailList > TRAIL_LOG_LIMIT then
				table.remove(trailList, #trailList)
			end

			lastTrailUpdateTime = currentClock
			lastTrailUpdatePosition = currentPosition
		end
		debug.profileend()

		debug.profilebegin("KeyGroup > Loop > Handle Keys")

		local speedDelta = (deltaTime * LERP_SPEED)
		for keyID, key in cache.keys do
			if not key or not key.instance or not key.__private then
				continue
			end
			local keyData = key.__private

			debug.profilebegin("KeyGroup > Loop > Handle Keys > Key")

			local keyIndex = table.find(cache.activeKeys, keyID)
			if (keyIndex ~= nil and keyData.active) and typeof(keyData.startTimer) == "number" then
				debug.profilebegin("KeyGroup > Loop > Handle Keys > Key > Handle Key Timer")
				local elapsedTime = (currentClock - keyData.startTimer)
				local timer = key.config.Timer
				if elapsedTime >= timer then
					keyData.returnKey(key :: Key)
				else
					local timerLabel = key.timerLabel
					if timerLabel then
						local config = key.config
						local formatted = formatTimer(config.TimerText, config.TimerDecimalPlaces, timer - elapsedTime)
						if timerLabel.Text ~= formatted then
							timerLabel.Text = formatted
						end
					end
				end
				debug.profileend()
			end

			debug.profilebegin("KeyGroup > Loop > Handle Keys > Key > Position Key")

			local targetPosition: Vector3 | CFrame = key.originalCFrame.Position
			if keyData.isViewportDisplayed then
				debug.profileend()
				debug.profileend()
				continue
			elseif keyData.targetCFrame then
				targetPosition = keyData.targetCFrame
			elseif keyIndex ~= nil then
				targetPosition = trailList[math.floor(TRAIL_DISTANCE * keyIndex)]
					or trailList[#trailList]
					or currentPosition
					or Vector3.zero
			end

			if
				((not keyData.active) and not keyData.cooldown and not keyData.used)
				and (targetPosition - cameraPosition).Magnitude > MAX_PIVOT_DISTANCE
			then
				debug.profileend()
				debug.profileend()
				continue
			end

			local finalPosition: CFrame
			if typeof(targetPosition) == "Vector3" then
				finalPosition = CFrame.new(key.instance:GetPivot().Position:Lerp(targetPosition, speedDelta))
			elseif typeof(targetPosition) == "CFrame" then
				finalPosition = key.instance:GetPivot():Lerp(targetPosition, speedDelta)
			end

			local rotation = math.rad((currentClock * (RADIANS_PER_SECOND * key.config.SpinSpeed)) % 360)
			key.instance:PivotTo(finalPosition * CFrame.Angles(0, rotation, 0))

			debug.profileend()
			debug.profileend()
		end

		debug.profileend()
		debug.profileend()
	end))

	utility.Gui.bindKeyCache(cache)
	rootScope:add(function()
		utility.Gui.unbindKeyCache(cache)
	end)

	return cache
end

function KeyGroup.Run(scope: _T.Scope, utility: _T.Utility)
	local keyGroupConfig = scope.instance
	if not keyGroupConfig or not keyGroupConfig.Parent then
		return
	end

	local keyGroup = keyGroupConfig.Parent

	local Config = utility.Config

	local cache = utility.Scope.getCached(scope, "keyGroup_cache", handleKeyCache)
	local thisGroup = cache.newGroup(scope)
	scope:attach(keyGroup)

	for _, instance: Instance in keyGroup:GetChildren() do
		local hitbox: Instance? = instance:FindFirstChild("Hitbox")
		if instance:IsA("Model") and (hitbox and hitbox:IsA("BasePart")) then
			if instance.Name == "Key" then
				--> Key Functionality
				instance.PrimaryPart = hitbox
				local timerGui = hitbox:FindFirstChild("KeyTimer")
					or (function()
						local newTimerGui = script.KeyTimer:Clone()
						newTimerGui.Parent = hitbox
						return newTimerGui
					end)()

				local keyConfig =
					Config.GetConfig(scope, instance:FindFirstChild("KeyConfiguration"), KEY_CONFIG_TEMPLATE)
						:ObserveChanges()

				local thisKey = assert(thisGroup:addKey({
					instance = instance,
					originalCFrame = instance:GetPivot(),
					hitbox = hitbox,
					timerBillboard = timerGui,
					timerLabel = timerGui:FindFirstChildWhichIsA("TextLabel"),
					config = keyConfig,
				}))

				local keyData = assert(thisKey.__private)
				scope:add(hitbox.Touched:Connect(function(toucher: BasePart)
					if
						keyData.active
						or keyData.cooldown
						or keyData.used
						or hitbox:GetAttribute("Activated") == false
						or not utility.ClientObjects.evaluateToucher(hitbox, toucher)
					then
						return
					end

					keyData.collectKey(thisKey)
				end))
			elseif instance.Name == "Door" then
				--> Door Functionality
				local parts: { [BasePart]: string? } = {}
				local signs: { [TextLabel]: string } = {}
				local doorParts = instance:FindFirstChild("DoorParts")
				for _, part in instance:GetDescendants() do
					if doorParts and part:IsA("BasePart") and part:IsDescendantOf(doorParts) then
						parts[part] = if DOOR_DESTROY_METHODS[part.Name:lower()] ~= nil
							then part.Name:lower()
							else "destroy"
					elseif part:IsA("TextLabel") then
						signs[part] = part.Text
					end
				end

				local doorConfig =
					Config.GetConfig(scope, instance:FindFirstChild("DoorConfiguration"), DOOR_CONFIG_TEMPLATE)
						:ObserveChanges()

				local thisDoor = assert(thisGroup:addDoor({
					instance = instance,
					hitbox = hitbox,
					doorParts = parts,
					doorSigns = signs,
					config = doorConfig,
				}))
				local doorData = assert(thisDoor.__private)
				local cooldown = false
				scope:add(hitbox.Touched:Connect(function(toucher: BasePart)
					if
						cooldown
						or doorData.unlocked
						or hitbox:GetAttribute("Activated") == false
						or not utility.ClientObjects.evaluateToucher(hitbox, toucher)
					then
						return
					end
					cooldown = true
					task.delay(0.5, function()
						cooldown = false
					end)

					for _, key in thisGroup.keys do
						if not key.__private or not key.__private.active then
							continue
						end
						doorData.useKey(thisDoor, key.__private.id)
					end
				end))
			end
		end

		if instance:IsA("BasePart") and instance:HasTag("ReturnKey") then
			--> Return key Functionality
			local cooldown = false
			scope:add(instance.Touched:Connect(function(toucher: BasePart)
				if
					cooldown
					or instance:GetAttribute("Activated") == false
					or not utility.ClientObjects.evaluateToucher(instance, toucher)
				then
					return
				end
				cooldown = true
				task.delay(0.5, function()
					cooldown = false
				end)

				for _, key in thisGroup.keys do
					local keyData = key.__private
					if keyData then
						keyData.returnKey(key :: Key)
					end
				end
			end))
		end
	end
end

return KeyGroup
