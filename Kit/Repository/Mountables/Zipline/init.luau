--!strict
--!optimize 2
--@version zipline-6.1.3
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
local RunService = game:GetService("RunService")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local CONTROL_ACCEL_TIME = 1 / 0.25
local TOUCH_COOLDOWN = 0.1

local Zipline = {
	CanQueue = true,
	RunOnStart = false,
}

local function bezier(alpha: number, pointTable: { Vector3 }): Vector3
	pointTable = table.clone(pointTable)
	while #pointTable > 1 do
		for i = 1, #pointTable - 1 do
			pointTable[i] = pointTable[i]:Lerp(pointTable[i + 1], alpha)
		end
		pointTable[#pointTable] = nil
	end

	return pointTable[1]
end

local CatRom = require(script.CatRom)
local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local ZIPLINE_CONFIG_TEMPLATE
function Zipline.Init(utility: _T.Utility)
	local Config = utility.Config
	ZIPLINE_CONFIG_TEMPLATE = {
		AllowEndDismount = true,
		AllowJumpDismount = true,
		AllowUserControl = false,
		HandleAnimation = true,
		KeepMomentum = false,
		RopeLength = 0,
		Segments = 20,
		Speed = 5,
		Loop = false,
		JumpOnDismount = true,
		StartInCenter = false,
		UseWeld = false,
		CurveMode = Config.Type.Some("Linear", "Bezier", "Spline", Config.Type.none),
	}
end

function Zipline.Run(scope: _T.Scope, utility: _T.Utility)
	local ziplineConfig = scope.instance
	if not ziplineConfig or not ziplineConfig.Parent then
		return
	end
	
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, ziplineConfig, ZIPLINE_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, ziplineConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
		:ObserveChanges()

	local zipline = ziplineConfig.Parent
	local mountPart = zipline:FindFirstChild("MountPart") :: BasePart
	local pointFolder = zipline:FindFirstChild("Points")
	local rideTemplate = zipline:FindFirstChild("RideModel") :: Model
	if not (mountPart and pointFolder and rideTemplate) then
		local errorName = if zipline then zipline.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end
	
	local baseSegment = zipline:FindFirstChild("BaseSegment") or script.BaseSegment
	local baseSegmentIsDefault = false
	if not baseSegment or not baseSegment:IsA("BasePart") then
		scope:log({`{zipline.Name} has an incorrectly set up BaseSegment. It must be a Part.`, type = "warn"})
		return
	end
	
	if baseSegment == script.BaseSegment then
		baseSegment = baseSegment:Clone()
		baseSegmentIsDefault = true
	end
	baseSegment.Parent = nil
	
	if not configuration.CurveMode then
		configuration.CurveMode = "Bezier" -- legacy compatibility
	end

	scope:add(rideTemplate)
	rideTemplate.Parent = nil

	for _, point in pointFolder:GetChildren() do
		if not point:IsA("BasePart") then
			continue
		end
		point.Transparency = 1
		point.CanCollide = false
		point.Size = Vector3.zero
	end

	local player = Players.LocalPlayer

	local playerModule = player.PlayerScripts:WaitForChild("PlayerModule")
	local controls = require(playerModule.ControlModule)

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local soundsFolder = zipline:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = zipline
			return newSounds
		end)()
	local effectsFolder = zipline:FindFirstChild("GuideEffects")
		or (function()
			local newEffects = Instance.new("Folder")
			newEffects.Parent = zipline
			return newEffects
		end)()
	local particleEmitter = effectsFolder:FindFirstChildOfClass("ParticleEmitter")
		or (function()
			local blankParticle = Instance.new("ParticleEmitter")
			blankParticle.Parent = effectsFolder
			blankParticle.Transparency = NumberSequence.new(1)
			return blankParticle
		end)()
	local loopSound = soundsFolder:FindFirstChild("Move") :: Sound
		or (function()
			local blankSound = Instance.new("Sound")
			blankSound.Parent = effectsFolder
			return blankSound
		end)()

	scope:attach(zipline)
	
	----------------------------------------------------------------------------
	
	--> Set up curve
	-- enforce a segment limit (to reduce lag, i promise this will be smooth enough)
	local segmentLimit = if mountPart.Anchored then 200 else 100
	configuration.Segments = math.floor(math.min(configuration.Segments, segmentLimit))

	local pointTable: { Vector3 } = if configuration.StartInCenter
		then {} 
		else {mountPart.Position}
	local segments: { BasePart } = {}

	for pointNum = 1, #pointFolder:GetChildren() do
		local point = pointFolder:FindFirstChild(tostring(pointNum))
		if not point or not point:IsA("BasePart") then
			continue
		end

		table.insert(pointTable, point.Position)
	end
	
	local curveMode = configuration.CurveMode

	if #pointTable <= 2 then
		configuration.Segments = 1
	end
	if curveMode == "Linear" then
		configuration.Segments = #pointTable - 1
	end
	
	local spline = CatRom.new(pointTable, 0.5, 0)
	
	local previousCurvePos =
		if curveMode == "Bezier" then bezier(0, pointTable)
		elseif curveMode == "Spline" then spline:SolvePosition(0, true)
		else mountPart.Position
	
	for segmentNum = 1, configuration.Segments do
		local alpha = segmentNum / configuration.Segments
		
		local nextCurvePos = 
			if curveMode == "Bezier" then bezier(alpha, pointTable)
			elseif curveMode == "Spline" then spline:SolvePosition(alpha, true)
			else pointTable[segmentNum + 1]
		
		if typeof(previousCurvePos) ~= "Vector3" or typeof(nextCurvePos) ~= "Vector3" then
			continue
		end
		
		if nextCurvePos == previousCurvePos then
			continue
		end
		
		local newSegment = baseSegment:Clone()
		newSegment.Name = `Segment{segmentNum}`
		newSegment.Anchored = false
		if baseSegmentIsDefault then
			newSegment.Color = mountPart.Color
		end
		
		local segmentWeld = Instance.new("WeldConstraint")
		segmentWeld.Part0 = newSegment
		segmentWeld.Part1 = mountPart
		segmentWeld.Parent = newSegment
		
		newSegment.Size = Vector3.new((nextCurvePos - previousCurvePos).Magnitude, newSegment.Size.Y, newSegment.Size.Z)
		newSegment.CFrame = CFrame.lookAt(previousCurvePos, nextCurvePos) * CFrame.Angles(0, math.pi * 0.5, 0)
		newSegment.CFrame += newSegment.CFrame.RightVector * (newSegment.Size.X * 0.5)
		newSegment.Parent = zipline
		table.insert(segments, newSegment)

		previousCurvePos = nextCurvePos
	end

	----------------------------------------------------------------------------
	--> Zipline riding
	local JumpButton = utility.JumpButton
	local rideDebounce = {}
	local touchDebounce = false
	local function ride(attachTo: BasePart, isPlayer: boolean)
		if mountPart:GetAttribute("Activated") == false or touchDebounce or rideDebounce[attachTo] then
			return
		end

		local humanoid = utility.Character.getHumanoid()
		local rideScope = scope:inherit()

		touchDebounce = true
		task.delay(0.1, function()
			touchDebounce = false
		end)

		rideDebounce[attachTo] = true
		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][zipline] = "Zipline"
		utility.Functions.playSoundFromInstance(mountPart, soundsFolder, "Grab")

		------------------------------------------------------------------------
		--> Create ride model
		local segmentStartCF = 
			(segments[1].CFrame - segments[1].CFrame.RightVector * (segments[1].Size.X * 0.5))
			* CFrame.Angles(0, -math.pi * 0.5, 0)
		local rideModel = rideTemplate:Clone()
		rideModel:PivotTo(segmentStartCF)
		rideModel.Parent = zipline
		rideScope:attach(rideModel)

		local ropeBar = rideModel:FindFirstChild("RopeBar") :: BasePart
		local ropeGuide = rideModel:FindFirstChild("RopeGuide") :: BasePart
		if not (ropeBar and ropeGuide) then
			rideModel:Destroy()
			return
		end

		local constraint = if configuration.UseWeld
			then Instance.new("WeldConstraint")
			else ropeBar:FindFirstChildOfClass("RopeConstraint")
		local particleClone = particleEmitter:Clone()
		local loopSoundClone = loopSound:Clone()
		if not constraint then
			rideModel:Destroy()
			scope:log({ `The {script.Name} script does not have its rope bar correctly set up.`, type = "warn" })
			return
		end
		
		if constraint:IsA("RopeConstraint") then
			constraint.Length = configuration.RopeLength
			constraint.Color = mountPart.BrickColor
		elseif constraint:IsA("WeldConstraint") then
			ropeBar.CFrame = segmentStartCF * CFrame.new(0, -configuration.RopeLength, 0)
			
			constraint.Part0 = ropeBar
			constraint.Part1 = ropeGuide
			constraint.Parent = ropeBar
		end
		particleClone.Parent = ropeGuide
		particleClone.Rate = configuration.Speed
		particleClone.Enabled = true
		loopSoundClone.Parent = ropeGuide
		if not configuration.AllowUserControl then
			loopSoundClone:Play()
		end
		
		ropeBar.Color = mountPart.Color
		ropeBar.Anchored = false

		attachTo.CFrame = mountPart.CFrame - mountPart.CFrame.UpVector * (attachTo.Size.Y / 2 + 1)
		if isPlayer and humanoid then
			utility.Character.carryPart(true, ropeBar, not configuration.HandleAnimation)
			humanoid.PlatformStand = true
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachTo
			barWeld.Parent = ropeBar
		end

		------------------------------------------------------------------------
		--> Ride variables
		local currentSegment = if configuration.StartInCenter
			then math.max(1, math.floor(#segments / 2))
			else 1
		local segmentProgress = if configuration.StartInCenter and segments[currentSegment]
			then segments[currentSegment].Size.X * if #segments % 2 == 0 then 0 else 0.5
			else 0
		local currentDirection = if configuration.AllowUserControl then 0 else 1
		-- 1 = forward, 0 = idle, -1 = backward

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountZipline()
			rideScope:cleanup(true, true)

			if isPlayer and humanoid then
				utility.Character.carryPart(false, ropeBar, not configuration.HandleAnimation)
				humanoid.PlatformStand = false
				
				if configuration.JumpOnDismount then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			utility.Functions.playSoundFromInstance(attachTo, soundsFolder, "Jump")

			if mountedCOs[attachTo] and mountedCOs[attachTo][zipline] then
				mountedCOs[attachTo][zipline] = nil
				if utility.Table.IsEmpty(mountedCOs[attachTo]) then
					mountedCOs[attachTo] = nil
				end
			end

			task.delay(TOUCH_COOLDOWN, function()
				rideDebounce[attachTo] = nil
			end)

			if not attachTo then
				return
			end
			if configuration.KeepMomentum and segments[currentSegment] then
				attachTo.AssemblyLinearVelocity = segments[currentSegment].CFrame.RightVector
					* configuration.Speed
					* currentDirection
			else
				attachTo.AssemblyLinearVelocity = Vector3.zero
			end
		end

		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountZipline()
			end))
		end

		------------------------------------------------------------------------
		--> Move ride
		rideScope:add(RunService.Heartbeat:Connect(function(deltaTime: number)
			debug.profilebegin("Zipline Movement")
			local segmentPart = segments[currentSegment]
			if not segmentPart then
				rideScope:cleanup(true, true)
				return
			end

			local goalCF = segmentPart.CFrame
				+ segmentPart.CFrame.RightVector * (segmentProgress - (segmentPart.Size.X * 0.5))
			ropeGuide.CFrame = goalCF * CFrame.Angles(0, -math.pi * 0.5, 0)

			segmentProgress += currentDirection * configuration.Speed * deltaTime
			segmentProgress = math.clamp(
				segmentProgress,
				if currentSegment <= 1 then 0 else -math.huge,
				if currentSegment >= #segments then segmentPart.Size.X else math.huge
			)
			local ziplineBlocked = (currentSegment <= 1 and segmentProgress <= 0)
				or (currentSegment >= #segments and segmentProgress >= segmentPart.Size.X)

			local finishedSegmentUpdate = false
			if currentDirection > 0 then
				repeat
					if segmentProgress > segmentPart.Size.X and currentSegment < #segments then
						currentSegment += 1
						segmentProgress -= segmentPart.Size.X

						local newSegment = segments[currentSegment]
						if not newSegment then
							rideScope:cleanup(true, true)
							return
						end
						segmentPart = newSegment
					else
						finishedSegmentUpdate = true
					end
				until finishedSegmentUpdate
			elseif currentDirection < 0 then
				repeat
					if segmentProgress < 0 and currentSegment > 1 then
						currentSegment -= 1
						local newSegment = segments[currentSegment]
						if not newSegment then
							rideScope:cleanup(true, true)
							return
						end
						segmentProgress += newSegment.Size.X
						segmentPart = newSegment
					else
						finishedSegmentUpdate = true
					end
				until finishedSegmentUpdate
			end

			if configuration.AllowUserControl then
				local controlVector = -controls:GetMoveVector().Z

				local directionIncrement = CONTROL_ACCEL_TIME * deltaTime
				if currentDirection < controlVector then
					currentDirection = math.clamp(currentDirection + directionIncrement, -1, controlVector)
				elseif currentDirection > controlVector then
					currentDirection = math.clamp(currentDirection - directionIncrement, controlVector, 1)
				end

				if currentDirection == 0 or ziplineBlocked then
					if particleClone.Enabled then
						particleClone.Enabled = false
					end
					if loopSoundClone.Playing then
						loopSoundClone:Stop()
					end
				elseif currentDirection ~= 0 and not ziplineBlocked then
					if not particleClone.Enabled then
						particleClone.Enabled = true
					end
					if not loopSoundClone.Playing then
						loopSoundClone:Play()
					end
				end
			end

			if not attachTo or not attachTo.Parent or not (mountedCOs[attachTo] and mountedCOs[attachTo][zipline]) then
				dismountZipline()
			end

			if currentSegment >= #segments and segmentProgress >= segmentPart.Size.X then
				if configuration.AllowEndDismount then
					dismountZipline()
				elseif configuration.Loop then
					currentSegment = 1
					segmentProgress = 0
				end
			elseif currentSegment == 1 and segmentProgress <= 0 and configuration.Loop and currentDirection < 0 then
				currentSegment = #segments
				segmentProgress = segments[#segments].Size.X
			end
			debug.profileend()
		end))
	end

	--> Activation
	scope:add(mountPart.Touched:Connect(function(touch)
		if touchDebounce or not utility.ClientObjects.evaluateToucher(mountPart, touch, touchConfiguration) then
			return
		end

		local characterInstances = utility.Character.getCharacter()
		local character = characterInstances.character
		local humanoid = characterInstances.humanoid
		local rootPart = characterInstances.rootPart
		if not rootPart then
			return
		end

		local isPlayer = table.find(utility.Character.getHitbox("StaticWholeBody"), touch) ~= nil
		local isBox = utility.ClientObjects.isPushbox(touch, true)
		if not (isPlayer or isBox) then
			return
		end

		local attachTo = if isPlayer then rootPart else touch
		if rideDebounce[attachTo] then
			return
		end

		ride(attachTo, isPlayer)
	end))

	if touchConfiguration.canFlip then
		mountPart:AddTag("DoNotFlipPlayer")
		scope:add(utility.ClientObjects.bindToFlip(mountPart, function(rootPart)
			ride(rootPart, true)
		end))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[zipline] = function()
		local rootPart = utility.Character.getCharacter().rootPart
		if not rootPart then
			return
		end
		ride(rootPart, true)
	end
	scope:add(function()
		cache[zipline] = nil
		cache = nil :: any
	end)
end

return Zipline
