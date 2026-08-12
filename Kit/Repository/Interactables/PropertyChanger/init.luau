--!strict
--!optimize 2
--@version propertychanger-6.1.3
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

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.TypeDefs)
local SequencerSupport = require(script.SequencerSupport)

type ChangerData = _TDefs.ChangerData

local TWEENABLE_TYPES = {
	number = true,
	CFrame = true,
	Rect = true,
	Color3 = true,
	UDim = true,
	UDim2 = true,
	Vector2 = true,
	Vector2int16 = true,
	Vector3 = true,
	boolean = false, -- booleans can be tweened but i'm not including that here
}

-- DO NOT CHANGE THIS VARIABLE AT ALL --
local BLACKLISTED_CLASSES = {
	Tool = true,
	HopperBin = true,
	ClickDetector = true,
	DragDetector = true,
	DataModel = true,
	Workspace = true,
	ReplicatedStorage = true,
	Player = true,
}

local PropertyChanger = {
	CanQueue = true,
	RunOnStart = false,
}

local CHANGER_CONFIG_TEMPLATE = {
	Throttle = 50,
	Cooldown = 0.5,
	ConditionalEnabled = false,
	ConditionalBreakSequence = false,
	ConditionalYield = false,
	SilenceWarnings = false,
}

local hierarchyMethods = _TDefs.Methods

local function printWarn(changerData: ChangerData, logData: any)
	if changerData.silenced then
		return
	end
	
	changerData.scope:log(logData)
end

local function variableNotFound(data: ChangerData, variable: string)
	printWarn(data, {
		`Could not find the sequencer variable "{variable}".`,
		`Path: {data.changer:GetFullName()}`,
		type = "warn",
	})
end

local function handleCache(rootScope: _T.Scope, utility: _T.Utility): _TDefs.Cache
	local cache = { tagged = {}, changers = {}, registered = {} }
	local shared = rootScope.shared
	local clientObjects = rootScope.clientObjects
	local characterInstances = utility.Character.getCharacter()
	local localPlayer = Players.LocalPlayer
	local function tagFilter(instance: Instance)
		if BLACKLISTED_CLASSES[instance.ClassName] then
			return false
		end

		if
			instance:IsDescendantOf(clientObjects)
			or (characterInstances and instance:IsDescendantOf(characterInstances.character))
		then
			return true
		end
		if typeof(shared.GuiContainer) == "Instance" and instance:IsDescendantOf(shared.GuiContainer) then
			return true
		elseif instance:IsDescendantOf(shared.TempContainer) then
			return true
		end

		return false
	end

	cache.filter = tagFilter
	function cache.getTagged(tag: string)
		local tagged = cache.tagged[tag]
		if tagged then
			return tagged
		end

		tagged = utility.Table.Filter(CollectionService:GetTagged(tag), tagFilter)
		cache.tagged[tag] = tagged
		rootScope:add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			local index = table.find(tagged, instance)
			if index then
				table.remove(tagged, index)
			end
		end))
		rootScope:add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if tagFilter(instance) and not table.find(tagged, instance) then
				table.insert(tagged, instance)
			end
		end))

		return tagged
	end

	rootScope:add(function()
		table.clear(cache.tagged)
		cache = nil :: any
	end)

	--> Property Fetcher Functions
	function cache.resolveHierarchy(instance, hierarchy)
		if not hierarchy then
			return instance
		end

		local newInstance: (Instance | { Instance })? = instance
		for _, value in hierarchy do
			if not newInstance or typeof(newInstance) == "table" then
				break
			elseif value.name then
				newInstance = newInstance:FindFirstChild(value.name, value.descendant)
			elseif value.class then
				newInstance = newInstance:FindFirstChildWhichIsA(value.class, value.descendant)
			elseif value.ancestor then
				newInstance = newInstance:FindFirstAncestor(value.ancestor)
			elseif value.classAncestor then
				newInstance = newInstance:FindFirstAncestorWhichIsA(value.classAncestor)
			elseif value.parent then
				newInstance = newInstance.Parent
			elseif value.children or value.descendants then
				if not cache.filter(newInstance) then
					newInstance = nil
					continue
				end

				if value.children then
					newInstance = newInstance:GetChildren()
				elseif value.descendants then
					newInstance = newInstance:GetDescendants()
				end
				break
			end
		end

		if typeof(newInstance) == "Instance" and not cache.filter(newInstance) then
			--> Make sure that the instance doesn't go outside of the client
			--> objects folder or the GUIs folder
			--> DO NOT REMOVE THIS CHECK!!
			newInstance = nil
		end

		return newInstance
	end

	local PlayerModule = require(localPlayer.PlayerScripts:WaitForChild("PlayerModule"))
	local ControlModule = PlayerModule:GetControls()
	local CameraModule = PlayerModule:GetCameras()

	local function isFirstPerson(): boolean
		if not characterInstances.primaryPart then
			return false
		end

		return characterInstances.primaryPart.LocalTransparencyModifier > 0.5
	end

	cache.classMethodMap = {
		AddTag = {
			class = "Instance",
			method = function(instance: Instance, value: any)
				if typeof(value) ~= "string" then
					return
				end
				instance:AddTag(value)
			end,
		},
		RemoveTag = {
			class = "Instance",
			method = function(instance: Instance, value: any)
				if typeof(value) ~= "string" then
					return
				end
				instance:RemoveTag(value)
			end,
		},
		PivotTo = {
			class = "PVInstance",
			method = function(instance: PVInstance, value: CFrame)
				if typeof(value) ~= "CFrame" then
					return
				end
				instance:PivotTo(value)
			end,
		},
		ScaleTo = {
			class = "Model",
			method = function(instance: Model, value: number)
				if typeof(value) ~= "number" then
					return
				end
				instance:ScaleTo(value)
			end,
		},
	}

	--> Preset Values
	local valueMap = {
		PlayerName = localPlayer.Name,
		PlayerDisplayName = localPlayer.DisplayName,
		UserId = localPlayer.UserId,
		CharacterPosition = function()
			return localPlayer.Character:GetPivot().Position
		end,
		CharacterCFrame = function()
			return localPlayer.Character:GetPivot()
		end,
		Distance = function(_, position: Vector3)
			return localPlayer:DistanceFromCharacter(position)
		end,
		PlayerHealth = function()
			local health = 0
			local humanoid = characterInstances.humanoid
			if humanoid then
				health = humanoid.Health
			end

			return health
		end,
		HumanoidState = function()
			local state = nil
			local humanoid = characterInstances.humanoid
			if humanoid then
				state = humanoid:GetState()
			end

			return state
		end,
		ViewportSize = function()
			return Workspace.CurrentCamera.ViewportSize
		end,
		CameraCFrame = function()
			return Workspace.CurrentCamera.CFrame
		end,
		FormatTimer = function(_, text: string, decimalPlaces: number, timer: number)
			return utility.ClientObjects.formatTimerText(text, decimalPlaces, timer)
		end,
		SequenceVariable = function(data: ChangerData, variable: string)
			local variables = data.selectedVariables
			if not variables then
				variableNotFound(data, variable)
				return
			end

			local evaluated = variables[variable]
			if evaluated == nil or typeof(evaluated) == "Instance" then
				variableNotFound(data, variable)
				return
			end

			return evaluated
		end,
		MoveVector = function()
			return ControlModule:GetMoveVector()
		end,
		IsShiftLocked = function(_, checkFirstPerson: boolean?)
			local shiftlocked = CameraModule.activeMouseLockController.isMouseLocked
			local firstPerson = checkFirstPerson and isFirstPerson()

			return shiftlocked or firstPerson
		end,
		IsJumping = function()
			return utility.JumpButton.IsDown()
		end,
		IsKeyDown = function(key: string | Enum.KeyCode)
			return UserInputService:IsKeyDown(key)
		end,
		PreferredInput = function()
			return UserInputService.PreferredInput
		end,
	}
	local eventMap = {
		JumpRequest = function()
			return utility.JumpButton.JumpEvent.Event
		end,
	}

	--> Hashed instances to prevent the modules from accessing any instances
	local generateUID = utility.Functions.generateUID
	local function getHash(data: ChangerData, instance: Instance): string
		local instanceHashMap = data.instanceHashMap
		local hash = instanceHashMap.hashed[instance]
		if hash then
			return hash
		end

		local newHash = generateUID()
		instanceHashMap.hashed[instance] = newHash
		instanceHashMap.map[newHash] = instance
		return newHash
	end

	--> Get Property
	local propertyMethods
	local function newPropertyMetatable(data, hash)
		local this = setmetatable({ data = data.id, hash = hash }, propertyMethods)
		table.insert(data.instanceHashMap.destroy, this)
		return this
	end

	propertyMethods = {
		Event = function(self: any, eventName: string)
			local data = cache.registered[self.data]
			if not data then
				return
			end

			local instance = cache.resolveHierarchy(data.instanceHashMap.map[self.hash], self.hierarchy)
			if typeof(instance) ~= "Instance" then
				return
			end

			local event, success = utility.Property.getPropertySafe(instance, eventName)
			if not success or typeof(event) ~= "RBXScriptSignal" then
				--> Fallback to GetPropertyChangedSignal if we couldn't get the
				--> signal
				success, event = pcall(function()
					return instance:GetPropertyChangedSignal(eventName)
				end)
			end

			if not success or typeof(event) ~= "RBXScriptSignal" then
				printWarn(data, {
					`Could not find an event named "{eventName}".`,
					`Path: {data.changer:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				return
			end

			return event
		end,
		Property = function(self: any, property: string)
			local data = cache.registered[self.data]
			if not data then
				return
			end

			local instance = cache.resolveHierarchy(data.instanceHashMap.map[self.hash], self.hierarchy)
			if typeof(instance) ~= "Instance" then
				return
			end

			local value, success = utility.Property.getPropertySafe(instance, property)
			if not success then
				--> Fallback to attributes if we couldn't get the property
				value = instance:GetAttribute(property)
			end

			if value == nil or typeof(value) == "RBXScriptSignal" or typeof(value) == "function" then
				printWarn(data, {
					`Could not find any property or attribute named "{property}".`,
					`Path: {data.changer:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				return
			elseif typeof(value) == "Instance" then
				if not cache.filter(value) then
					return
				end

				return newPropertyMetatable(data, getHash(data :: any, value))
			end

			return value
		end,
	}
	propertyMethods.__index = propertyMethods
	propertyMethods = utility.Table.Merge(propertyMethods, hierarchyMethods)
	cache.propertyMethods = propertyMethods

	rootScope:add(function()
		propertyMethods.__index = nil :: any
		setmetatable(propertyMethods :: any, nil)
		propertyMethods = nil :: any
	end)

	local evaluatorMethods = {
		Tagged = function(data: ChangerData, tag: string)
			local firstTagged = cache.getTagged(tag)[1]
			if not firstTagged then
				printWarn(data, {
					`Could not find any tagged objects with the tag "{tag}".`,
					`Path: {data.changer:GetFullName()}`,
					type = "error",
				})
				return
			end

			return newPropertyMetatable(data, getHash(data, firstTagged))
		end,
		Changer = function(data: ChangerData)
			return newPropertyMetatable(data, getHash(data, data.changer))
		end,
		Toucher = function(data: ChangerData)
			if not data.touchingPart then
				return
			end
			return newPropertyMetatable(data, getHash(data, data.touchingPart))
		end,
		Instance = function(data: ChangerData)
			if not data.selectedInstance then
				return
			end
			return newPropertyMetatable(data, getHash(data, data.selectedInstance))
		end,
		Character = function(data: ChangerData)
			local character = characterInstances.character
			if not character then
				return
			end
			return newPropertyMetatable(data, getHash(data, character))
		end,
		SequenceInstance = function(data: ChangerData, variable: string)
			local variables = data.selectedVariables
			if not variables then
				variableNotFound(data, variable)
				return
			end

			local evaluated = variables[variable]
			if typeof(evaluated) ~= "Instance" then
				variableNotFound(data, variable)
				return
			end

			return newPropertyMetatable(data, getHash(data, evaluated))
		end,
		Value = function(data: ChangerData, value, ...)
			local value = valueMap[value]
			if typeof(value) == "function" then
				return value(data, ...)
			end

			return value
		end,
		Event = function(data: ChangerData, value, ...)
			local value = eventMap[value]
			if typeof(value) == "function" then
				return value(data, ...)
			end

			return value
		end,
	}

	-- evaluator methods are called without the colon notation, so the self
	-- variable isn't passed in. it's too late to change that so we have to do
	-- this stupid metatable workaround
	cache.evaluatorMetatable = {
		__newindex = function() end,
		__index = function(self, index)
			local target = evaluatorMethods[index]
			if typeof(target) ~= "function" then
				return
			end

			local function method(...)
				return target(cache.registered[self.data], ...)
			end
			rawset(self, index, method)
			return method
		end,
	}

	SequencerSupport(rootScope, utility, cache)
	return cache
end

function PropertyChanger.Run(scope: _T.Scope, utility: _T.Utility)
	local changerConfig = scope.instance
	if not changerConfig or not changerConfig.Parent then
		return
	end

	--> Get config module
	local Config = utility.Config

	--> Check for any misconfigurations
	local changer = changerConfig.Parent
	if not changer:IsA("BasePart") then
		scope:log({
			"Changer must be a BasePart",
			`Path: {changer:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end
	
	local propertyPointer = utility.Instance.getPointer(changerConfig:FindFirstChild("Properties"))
	if not propertyPointer or not propertyPointer:IsA("ModuleScript") then
		scope:log({
			"Property Changer is missing its 'Properties' module.",
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local propertyMap = require(propertyPointer) :: any
	if typeof(propertyMap) ~= "table" then
		scope:log({
			`Property Changer's property module returned "{typeof(propertyMap)}", expected table`,
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
	end

	--> Get Changer Configurations
	local changerConfiguration = Config.GetConfig(scope, changerConfig, CHANGER_CONFIG_TEMPLATE):ObserveChanges()
	local tagCache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	
	--> Extra property values
	local id = utility.Functions.generateUID()
	local changerData: ChangerData = {
		id = id,
		changer = changer,
		scope = scope,
		selectedInstance = nil,
		selectedVariables = nil,
		touchingPart = nil,
		silenced = changerConfiguration.SilenceWarnings,
		instanceHashMap = {
			hashed = {},
			map = {},
			destroy = {},
		},
	}

	tagCache.registered[id] = changerData
	local evaluatorMethods = setmetatable({ data = id }, tagCache.evaluatorMetatable)
	local instanceHashMap = changerData.instanceHashMap
	
	--> Main Functionality
	local function typeWarning(class: string, property: string, expected: string, got: string)
		printWarn(changerData, {
			`Property Type Check failed (setting {class}'s' '{property}' property expects '{expected}', got '{got}')`,
			`Path: {changerConfig:GetFullName()}`,
			type = "warn",
		})
	end
	
	local function createList(set: any, instance: Instance)
		local newList = {
			instance = instance,
			attributes = {} :: { [string]: any },
			properties = {} :: { [string]: any },
			tweens = {} :: { [TweenInfo]: { [string]: any } },
		}
		table.insert(set, newList)
		return newList
	end

	local function addToList(
		list: {},
		type: "tweens" | "attributes" | "properties",
		property: string,
		value: any,
		tweenInfo: TweenInfo?
	)
		local targetTable = list[type]
		if tweenInfo and type == "tweens" then
			-- tween types are grouped by tweeninfos
			if not targetTable[tweenInfo] then
				targetTable[tweenInfo] = {}
			end
			targetTable = targetTable[tweenInfo]
		end
		targetTable[property] = value
	end
	
	local characterInstances = utility.Character.getCharacter()
	local cooldown = false
	local function changeProperty(touchingPart: BasePart?, variables: { [string]: any })
		if cooldown then
			changerData.selectedVariables = nil
			return
		end
		if changerConfiguration.Cooldown > 0 and not changerConfiguration.ConditionalEnabled then
			cooldown = true
			task.delay(changerConfiguration.Cooldown, function()
				cooldown = false
			end)
		end

		changerData.touchingPart = touchingPart
		changerData.selectedVariables = variables
		local finalCondition = true
		local longestTweenTime = -1
		local propertiesToSet: any = {}
		for _, chunk in propertyMap do
			local instances = chunk.Instance
			local hierarchy = if typeof(instances) == "table" then instances.hierarchy else nil

			if typeof(instances) == "table" and instances.toucher or instances.changer then
				--> Touching Part or the Changer part itself
				local thisInstance: Instance? = if instances.changer then changer else touchingPart
				instances = { thisInstance }
			elseif typeof(instances) == "table" and typeof(instances.tag) == "string" then
				--> Tagged part
				instances = table.clone(tagCache.getTagged(instances.tag))
			elseif typeof(instances) == "table" and instances.character then
				--> Character
				instances = { characterInstances.character }
			elseif typeof(instances) == "table" and typeof(instances.variable) == "string" then
				--> Sequencer Variable
				local evaluated = variables[instances.variable]
				if typeof(evaluated) == "string" then --> Tag Variable
					instances = tagCache.getTagged(evaluated)
				elseif typeof(evaluated) == "Instance" then --> Instance
					instances = { evaluated }
				else
					variableNotFound(changerData, instances.variable)
					instances = nil
				end
			else
				instances = nil
			end

			if hierarchy and typeof(instances) == "table" then
				--> Resolve Hierarchy
				local newInstanceTable = {}
				for _, instance in instances do
					local instance = tagCache.resolveHierarchy(instance, hierarchy)
					if typeof(instance) == "Instance" then
						table.insert(newInstanceTable, instance)
					elseif typeof(instance) == "table" then
						--> children / descendants table
						for _, otherInstance in instance do
							table.insert(newInstanceTable, otherInstance)
						end
					end
				end

				instances = newInstanceTable
			end

			if typeof(instances) ~= "table" or #instances <= 0 then
				printWarn(changerData, {
					`No target instance(s) found.`,
					`Path: {changerConfig:GetFullName()}`,
					type = "warn",
				})
				continue
			end

			local blockCondition = true
			if typeof(chunk.BlockCondition) == "function" then
				changerData.selectedInstance = nil
				if not chunk.BlockCondition(evaluatorMethods) then
					blockCondition = false
					finalCondition = false
				end
			end

			local conditionFn
			if typeof(chunk.Condition) == "function" then
				conditionFn = chunk.Condition
			end

			local checkRate = 1 / 60
			local conditionalYield = changerConfiguration.ConditionalYield
			local tween = chunk.Tween
			for property, value in chunk do
				local destroyedInstance = false
				if
					property == "Instance"
					or property == "Tween"
					or property == "BlockCondition"
					or not blockCondition
					or destroyedInstance
				then
					continue
				end

				for i, instance: Instance in instances do
					changerData.selectedInstance = instance
					if conditionFn then
						local conditionPassed
						-- the below only runs once if ConditionalYield is
						-- disabled
						repeat
							conditionPassed = conditionFn(evaluatorMethods)
							if conditionalYield and not conditionPassed then
								task.wait(checkRate)
							end
						until (not conditionalYield) or conditionPassed

						if not conditionPassed then
							finalCondition = false
							changerData.selectedInstance = nil
							continue
						end
					end

					if property == "Condition" then
						--> if this is the condition function itself, skip the
						--> rest of the loop
						changerData.selectedInstance = nil
						continue
					end

					local thisValue = if typeof(value) == "function" then value(evaluatorMethods) else value
					changerData.selectedInstance = nil

					if property == "Event" and typeof(thisValue) == "RBXScriptSignal" then
						--> Wait for signals and skip the rest of the loop
						thisValue:Wait()
						continue
					end

					if changerConfiguration.ConditionalEnabled then
						--> Skip changing properties conditional mode is enabled
						continue
					end

					local currentValue, isProperty = utility.Property.getPropertySafe(instance, property)
					local currentType = typeof(currentValue)
					local thisType = typeof(thisValue)
					if typeof(thisValue) == "table" and thisValue.hash then
						--> If we have an instance hash, get the actual instance
						--> from the hash
						thisValue = tagCache.resolveHierarchy(instanceHashMap.map[thisValue.hash], thisValue.hierarchy)
						thisType = typeof(thisValue)
					end

					if currentType == "Instance" and thisType == "nil" then
						if property == "Parent" then
							-- instead of setting the parent to nil just destroy
							-- we don't want the instance lingering in memory
							-- and there would've been no way to access it if it
							-- was in nil either way
							instance:Destroy()
							destroyedInstance = true
							continue
						end

						-- Instances can be set to nil, so just force the type
						-- check to be true
						thisType = "Instance"
					end

					local propertyOverride = tagCache.classMethodMap[property]
					if propertyOverride and instance:IsA(propertyOverride.class) then
						propertyOverride.method(instance, thisValue)
						continue
					end

					local thisList = createList(propertiesToSet, instance)
					if isProperty and thisType ~= currentType then
						typeWarning(instance.ClassName, property, currentType, thisType)
					elseif isProperty and thisType == currentType then
						if typeof(tween) == "TweenInfo" and tween.Time > 0 and TWEENABLE_TYPES[thisType] then
							addToList(thisList, "tweens", property, thisValue, tween)
							if tween.Time > longestTweenTime then
								longestTweenTime = tween.Time
							end
						else
							addToList(thisList, "properties", property, thisValue)
						end
					else
						-- TODO: attribute tweening?? (probably expensive)
						addToList(thisList, "attributes", property, thisValue)
					end
				end
			end
		end

		--> Clear variables & hash
		changerData.selectedInstance = nil
		changerData.selectedVariables = nil
		table.clear(instanceHashMap.map)
		table.clear(instanceHashMap.hashed)
		for _, meta in instanceHashMap.destroy do
			setmetatable(meta, nil)
			table.clear(meta)
		end
		table.clear(instanceHashMap.destroy)

		if changerConfiguration.ConditionalEnabled then
			--> Sequencer Property Checker Conditionals
			--> Also skips setting any properties if this is enabled
			local code = if changerConfiguration.ConditionalBreakSequence then "BREAK_LOOP" else "STOP_SEQUENCE"
			return if finalCondition then true else code
		end

		--> Set Values
		local throttleCount = changerConfiguration.Throttle
		local totalSet = 0
		for _, data in propertiesToSet do
			local instance = data.instance
			for property, value in data.attributes do
				instance:SetAttribute(property, value)
			end
			for property, value in data.properties do
				utility.Property.setPropertySafe(instance, property, value)
			end
			for info, goal in data.tweens do
				utility.Functions.tween(
					instance,
					info.Time,
					goal,
					info.EasingStyle,
					info.EasingDirection,
					info.RepeatCount,
					info.Reverses,
					info.DelayTime
				)
			end

			--> Throttle
			totalSet += 1
			if totalSet % throttleCount == 0 then
				task.wait()
			end
		end
		table.clear(propertiesToSet)

		if longestTweenTime > 0 then
			task.wait(longestTweenTime)
		end
	end

	--> Activation
	local touchConfiguration =
		Config.GetConfig(scope, changerConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
		:ObserveChanges()

	scope:attach(changer)
	scope:add(changer.Touched:Connect(function(toucher)
		if
			cooldown
			or changer:GetAttribute("Activated") == false
			or (not utility.ClientObjects.evaluateToucher(changer, toucher, touchConfiguration))
		then
			return
		end

		changeProperty(toucher, {})
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(changer, function(rootPart)
			if cooldown or changer:GetAttribute("Activated") == false then
				return
			end
			changeProperty(rootPart, {})
		end))
	end

	--> Sequencer cache support
	tagCache.changers[changer] = {
		forceAwait = changerConfiguration.ConditionalEnabled,
		change = changeProperty,
	}
	scope:add(function()
		setmetatable(evaluatorMethods :: any, nil)
		table.clear(evaluatorMethods :: any)
		evaluatorMethods = nil :: any
		tagCache.registered[id] = nil
		tagCache.changers[changer] = nil
		tagCache = nil :: any
	end)
end

return PropertyChanger
