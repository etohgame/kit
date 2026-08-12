--!strict
--!optimize 2
--@version sequencer-6.1.1
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

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local COMMUNICATOR = {
	KEY = "SequencerRequest",
	REGISTER_OBJECT = "register-object",
}

local STOPPED_COLOR = ColorSequence.new(Color3.fromRGB(255, 100, 100))
local PAUSED_COLOR = ColorSequence.new(Color3.fromRGB(255, 255, 100))
local PLAYING_COLOR = ColorSequence.new(Color3.fromRGB(45, 150, 255))
local LOOP_TRACK_SECONDS = 5
local LOOP_MAX_RATE = 25

local SetupPresetActivators = require(script.Activators)
local _TDefs = require(script.TypeDefs)
type SequenceData = _TDefs.SequenceData
type ActivatorData = _TDefs.ActivatorData
type SequencerCache = _TDefs.SequencerCache

local function doNothing() end
local function optimizePart(part: Instance?)
	if not (part and part:IsA("BasePart")) then
		return
	end
	-- part.Transparency = 0
	-- part.Material = Enum.Material.SmoothPlastic
	part.CanTouch = false
	part.CanCollide = false
	part.CanQuery = false
	part.CollisionGroup = "NeverCollide"
	part:AddTag("IgnoreAll")
end

local function handleCache(scope: _T.Scope, utility: _T.Utility): SequencerCache
	local cache = { activators = {}, sequencers = {} } :: SequencerCache

	local function register(name: string, data: ActivatorData)
		if
			cache.activators[name] ~= nil
			or typeof(data) ~= "table"
			or typeof(data.check) ~= "function"
			or typeof(data.activate) ~= "function"
		then
			return
		end

		cache.activators[name] = data
	end

	local communicator = scope:getCommunicator("request", COMMUNICATOR.KEY)
	communicator:listen(function(type: string, ...: any)
		if type == COMMUNICATOR.REGISTER_OBJECT then
			return register(...)
		end
	end)

	function cache.fetchActivators(sequenceData: SequenceData)
		local sortTable = {}
		local optimizeFn = if sequenceData.doNotOptimize then doNothing else optimizePart
		for _, activator in cache.activators do
			if not activator.check(sequenceData, optimizeFn) then
				continue
			end
			table.insert(sortTable, {
				activator = activator.activate,
				priority = activator.priority or math.huge,
			})
		end

		table.sort(sortTable, function(a, b)
			return a.priority < b.priority
		end)

		return utility.Table.Map(sortTable, function(value)
			return value.activator
		end)
	end

	function cache.makeSequenceData(instance: PVInstance, forceAwait: boolean?, doNotOptimize: boolean?)
		local currentData: SequenceData = {
			canAwait = forceAwait or instance:HasTag("YieldSequence"),
			instance = instance,
			hasPassed = false,
			point = instance:GetPivot(),
			activatorData = {},
			doNotOptimize = doNotOptimize,
		}

		if instance:IsA("Model") and not instance.PrimaryPart then
			-- fix weird pivot data
			currentData.point = (instance:GetBoundingBox())
		end

		return currentData
	end

	SetupPresetActivators(register, utility, cache, scope)
	return cache
end

local function distanceBetween(pointA: CFrame, pointB: CFrame): number
	return pointA:ToObjectSpace(CFrame.new(pointB.Position)).Position.Z
end

local Sequencer = {
	CanQueue = true,
	RunOnStart = false,

	Communicator = COMMUNICATOR,
}
local SEQUENCER_CONFIG_TEMPLATE
local MUSIC_SYNC_CONFIG_TEMPLATE
local STOPPER_CONFIG_TEMPLATE
function Sequencer.Init(utility: _T.Utility)
	local Config = utility.Config
	SEQUENCER_CONFIG_TEMPLATE = {
		LoopAmount = 0,
		LoopDelay = 0,
		Cooldown = 0,
		Speed = 1,
		Visualize = false,
		RunAtStart = false,
		HideSequence = false,
	}
	MUSIC_SYNC_CONFIG_TEMPLATE = {
		ZoneName = Config.Type.string,
		SyncEnabled = false,
	}
	STOPPER_CONFIG_TEMPLATE = {
		BreakLoop = false,
	}
end

local musicManager
function Sequencer.Run(scope: _T.Scope, utility: _T.Utility)
	local sequencerConfig = scope.instance
	if not sequencerConfig or not sequencerConfig.Parent then
		return
	end

	--> Check for misconfigurations
	local clientObjectUtil = utility.ClientObjects
	if clientObjectUtil.isBalloon(sequencerConfig) or clientObjectUtil.isTurret(sequencerConfig) then
		scope:log({
			"Sequencer must not be parented to a Balloon or a Turret.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end
	local base = sequencerConfig.Parent:FindFirstChild("Base")
	if not base or not base:IsA("BasePart") then
		scope:log({
			"Sequencer Base either does not exist, or is not a BasePart.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local sequenceFolder = sequencerConfig.Parent:FindFirstChild("Sequence")
	if not sequenceFolder then
		scope:log({
			"Sequencer Sequence does not exist.",
			`Path: {sequencerConfig.Parent:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	-- these will not error if missing, they simply just won't do anything
	local sequenceActivators = sequencerConfig.Parent:FindFirstChild("Activators")
	local sequenceStoppers = sequencerConfig.Parent:FindFirstChild("Stoppers")

	--> Get Cache
	local cache = utility.Scope.getCached(scope, COMMUNICATOR.KEY, handleCache)

	--> Get Configuration
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, sequencerConfig, SEQUENCER_CONFIG_TEMPLATE):ObserveChanges()

	local musicSyncConfig = sequencerConfig:FindFirstChild("MusicSyncConfiguration")
	local syncConfiguration = Config.GetConfig(scope, musicSyncConfig, MUSIC_SYNC_CONFIG_TEMPLATE):ObserveChanges()

	local syncData
	if musicSyncConfig and syncConfiguration.SyncEnabled and syncConfiguration.ZoneName then
		local syncPointer = utility.Instance.getPointer(musicSyncConfig:FindFirstChild("Sync"))
		if syncPointer then
			syncData = utility.SongTime.BuildSyncCache(require(syncPointer) :: any)
		end
	end

	--> Setup Model
	base.Transparency = 1
	local beam: Beam?
	if configuration.Visualize then
		local attachment0 = Instance.new("Attachment")
		attachment0.Position = -Vector3.yAxis * (base.Size.Y * 0.5)
		attachment0.Orientation = Vector3.zAxis * 90
		attachment0.Parent = base

		local attachment1 = attachment0:Clone()
		attachment1.Position = -attachment1.Position
		attachment1.Parent = base

		beam = script:FindFirstChildWhichIsA("Beam"):Clone()
		if beam then
			beam.Attachment0 = attachment0
			beam.Attachment1 = attachment1
			beam.Width0, beam.Width1 = base.Size.X, base.Size.X
			beam.Color = STOPPED_COLOR
			beam.Parent = base
		end
	elseif configuration.HideSequence then
		-- Parent folder elsewhere
		-- note that property changers in the sequence may not work if they are
		-- trying to find objects that are inside the sequencer
		
		scope:add(sequenceFolder)
		sequenceFolder.Parent = scope.shared.TempContainer

		local baseIndicator = base:FindFirstChildWhichIsA("ConeHandleAdornment")
		if baseIndicator then
			baseIndicator:Destroy()
		end
	end

	local currentStatusColor = STOPPED_COLOR
	local function setStatusColor(color: ColorSequence)
		if not configuration.Visualize or not beam or currentStatusColor == color then
			return
		end
		currentStatusColor = color
		beam.Color = color
	end

	--> Fetch Sequence Data
	local sequenceData: { SequenceData } = {}
	local function iterFolder(folder: Instance)
		for _, child: Instance in folder:GetChildren() do
			if child:IsA("Folder") and child.Name ~= "SequenceGroup" then
				iterFolder(child)
				continue
			elseif not child:IsA("PVInstance") then
				continue
			end

			local currentData = cache.makeSequenceData(child)
			table.insert(sequenceData, currentData)
		end
	end
	iterFolder(sequenceFolder)
	table.sort(sequenceData, function(dataA, dataB)
		return dataA.point.Y < dataB.point.Y
	end)

	--> Sequencer Functionality
	local startingPosition = base:GetPivot()
	local fetchedActivators = false
	local runIndex = 0
	local sequenceScope = scope:inherit()
	local musicZone
	local zoneNotFound = false

	local function getCurrentSound(): boolean | Sound
		if not syncData then
			return true
		end

		if not musicZone then
			local backgroundMusic = ReplicatedStorage:WaitForChild("Background Music")
			if not musicManager then
				musicManager = require(backgroundMusic:WaitForChild("MusicSystemManager"))
			end

			if not musicZone and not zoneNotFound then
				local musicZonesContainer = backgroundMusic:WaitForChild("BackgroundMusicZones")
				musicZone = musicZonesContainer:FindFirstChild(syncConfiguration.ZoneName, true)
			end
			if not musicZone then
				zoneNotFound = true
				scope:log({ "Could not find music zone" })
				return false
			end
		end

		local currentZone = musicManager.CurrentZone
		if not currentZone or currentZone.instance ~= musicZone then
			return false
		end

		local currentSound = musicManager.CurrentSong
		if not currentSound or currentSound.zoneID ~= currentZone.id then
			return false
		end

		return currentSound.song
	end

	local function runSequence(variables: { [string]: any }): string?
		local currentSound = getCurrentSound()
		if not scope:isAlive() or not currentSound then
			-- fix not running when using RunAndStart and SyncEnabled
			-- when music is not preloaded
			if (not currentSound) and configuration.RunAtStart then
				local soundExists = utility.Functions.yieldTimeout(5, function()
					repeat
						currentSound = getCurrentSound()
						task.wait()
					until currentSound
						and currentSound.Playing
						and currentSound.TimePosition < currentSound.TimeLength - 0.1
					return true
				end)

				if not soundExists then
					return
				end
			end

			return
		end

		--> Fetch activators if we haven't already
		if not fetchedActivators then
			fetchedActivators = true
			-- Iterating backwards makes it easier to remove items as you're
			-- iterating through the table!!
			for i = #sequenceData, 1, -1 do
				local sequence = sequenceData[i]
				local activators = cache.fetchActivators(sequence)
				if #activators <= 0 and sequence.instance.Name ~= "EndPoint" then
					table.remove(sequenceData, i)
				else
					sequence.activators = activators
				end
			end
		end

		runIndex += 1
		local thisIndex = runIndex
		local isPaused = false
		local delta = 0

		-- clone sequence data (1 layer deep)
		local sequenceCount = #sequenceData
		local currentSequenceData = table.create(sequenceCount) :: typeof(sequenceData)
		for index, data in sequenceData do
			local this: any = {}
			for innerIndex, innerValue in data do
				this[innerIndex] = innerValue
			end
			currentSequenceData[index] = this
		end

		local runningThread = coroutine.running()
		sequenceScope:add(function()
			runIndex += 1
			setStatusColor(STOPPED_COLOR)
			base:PivotTo(startingPosition)
			currentSequenceData = nil :: any
			task.spawn(runningThread)
		end)

		local stopCode = ""
		local speed = -math.abs(configuration.Speed)
		local visualize = configuration.Visualize
		sequenceScope:add(RunService.PostSimulation:Connect(function(deltaTime)
			if runIndex ~= thisIndex or not currentSequenceData then
				sequenceScope:cleanup()
				return
			end
			if isPaused then
				setStatusColor(PAUSED_COLOR)
				return
			end

			if syncData then
				--> Handle Music Sync
				local soundInstance = getCurrentSound()
				if typeof(soundInstance) ~= "Instance" then
					sequenceScope:cleanup()
					return
				end

				local position = soundInstance.TimePosition
				delta = syncData:BeatFromSecond(position)
				if position >= soundInstance.TimeLength - 0.1 or not soundInstance.Playing then
					--Sound not playing or is (very close to being) done playing
					sequenceScope:cleanup()
					return
				end
			else
				delta += deltaTime
			end

			setStatusColor(PLAYING_COLOR)
			local currentPosition = startingPosition * CFrame.new(0, 0, delta * speed)
			if visualize then
				base:PivotTo(currentPosition)
			end

			local passed = 0
			for _, sequencePart in currentSequenceData do
				if sequencePart.hasPassed or not sequencePart.activators then
					-- sequencer has already passed this part, skip
					passed += 1
					continue
				end

				local distanceFromBase = distanceBetween(currentPosition, sequencePart.point)
				if distanceFromBase < 0 then
					-- sequencer still hasn't reached this part yet; skip
					continue
				end

				sequencePart.hasPassed = true
				passed += 1
				
				if sequencePart.canAwait then
					isPaused = true
				end
				for _, activator in sequencePart.activators do
					local success, returned: string? = pcall(activator, sequencePart, variables)
					if (not success) and typeof(returned) == "string" then
						scope:log({ `sequencer error: {returned}` })
					elseif success and returned == "STOP_SEQUENCE" or returned == "BREAK_LOOP" then
						stopCode = returned
						sequenceScope:cleanup()
						return
					end
				end
				if sequencePart.canAwait then
					isPaused = false
				end
			end

			if passed >= sequenceCount and not syncData then
				sequenceScope:cleanup()
				return
			end
		end))

		coroutine.yield()
		return stopCode
	end

	--> Main Functionality
	local stopLoop = false
	local isPlaying = false
	local totalRuns = 0
	local function sequenceWrapper(variables)
		if isPlaying then
			return
		end
		isPlaying = true
		stopLoop = false

		--> Get & set maximum values
		local loopDelay = math.max(configuration.LoopDelay, 1 / LOOP_MAX_RATE)
		local loopCount = configuration.LoopAmount
		if loopCount < 0 then
			loopCount = math.huge
		end

		local loopWarningCheck = false
		local loopStart = os.clock()
		for loop = 1, loopCount + 1 do
			if stopLoop then
				break
			end

			if not loopWarningCheck and (os.clock() - loopStart) > LOOP_TRACK_SECONDS then
				--> Check if the sequencer is looping at a fast rate
				loopWarningCheck = true

				local rate = loop // LOOP_TRACK_SECONDS
				if rate > LOOP_MAX_RATE then
					scope:log({
						`This sequencer seems to be looping at a fast rate (~{rate} times per second).`,
						`Please decrease the sequencer's "LoopDelay" to prevent any potential lag.`,
						`Path: {sequencerConfig.Parent:GetFullName()}`,
						type = "warn",
					})
				end
			end

			totalRuns += 1
			variables.CurrentLoop = loop
			variables.RunTimes = totalRuns
			local stopCode = runSequence(variables)
			if stopCode == "BREAK_LOOP" or stopLoop then
				break
			end
			if loopCount > 1 then
				task.wait(loopDelay)
			end
		end

		if configuration.Cooldown > 0 then
			task.wait(configuration.Cooldown)
		end
		isPlaying = false
		stopLoop = false
	end

	scope:attach(sequencerConfig.Parent)
	cache.sequencers[sequencerConfig.Parent] = sequenceWrapper

	--> Main functionality
	local characterInstances = utility.Character.getCharacter()

	if sequenceActivators then
		for _, activator in sequenceActivators:GetChildren() do
			if not activator:IsA("BasePart") then
				continue
			end

			local activatorVariables = activator:FindFirstChild("SequenceVariables")
			local function getVariables(): { [string]: any }
				local variables = {}
				if activatorVariables then
					variables = activatorVariables:GetAttributes()
				end

				return variables
			end

			local touchConfiguration =
				Config.GetConfig(scope, activator:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
					:ObserveChanges()

			scope:add(activator.Touched:Connect(function(toucher: BasePart)
				local character = characterInstances.character
				local rootPart = characterInstances.rootPart
				if
					activator:GetAttribute("Activated") == false
					or not utility.ClientObjects.evaluateToucher(activator, toucher, touchConfiguration)
					or (not character or not rootPart)
				then
					return
				end

				local touchingPart = if toucher:IsDescendantOf(character) then rootPart else toucher
				local variables = getVariables()
				variables.TouchingPart = touchingPart
				variables.ActivatingPart = activator
				scope:spawn(sequenceWrapper, variables)
			end))

			if touchConfiguration.canFlip then
				scope:add(utility.ClientObjects.bindToFlip(activator, function(rootPart)
					if activator:GetAttribute("Activated") == false then
						return
					end

					local variables = getVariables()
					variables.TouchingPart = rootPart
					variables.ActivatingPart = activator
					scope:spawn(sequenceWrapper, variables)
				end))
			end
		end
	end

	if sequenceStoppers then
		for _, stopper in sequenceStoppers:GetChildren() do
			if not stopper:IsA("BasePart") then
				continue
			end

			local touchConfiguration =
				Config.GetConfig(scope, stopper:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
					:ObserveChanges()
			local stopperConfiguration =
				Config.GetConfig(scope, stopper:FindFirstChild("StopperConfiguration"), STOPPER_CONFIG_TEMPLATE)
					:ObserveChanges()

			local function stop()
				if stopper:GetAttribute("Activated") == false then
					return
				end

				runIndex += 1
				stopLoop = stopperConfiguration.BreakLoop
			end

			scope:add(stopper.Touched:Connect(function(toucher: BasePart)
				if not utility.ClientObjects.evaluateToucher(stopper, toucher, touchConfiguration) then
					return
				end

				stop()
			end))

			if touchConfiguration.canFlip then
				scope:add(utility.ClientObjects.bindToFlip(stopper, stop))
			end
		end
	end

	if configuration.RunAtStart then
		scope:delay(0.1, sequenceWrapper, {})
	end
end

return Sequencer
