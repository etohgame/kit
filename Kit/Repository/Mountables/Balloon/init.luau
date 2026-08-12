--!strict
--!optimize 2
--@version balloon-6.1.3
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

local TOUCH_COOLDOWN = 0.1

local Balloon = {
	CanQueue = true,
	RunOnStart = false,
}

local BALLOON_CONFIG_TEMPLATE = {
	HandleAnimation = true,
	AllowJumpDismount = true,
	DestroyWhenExpired = true,
	KeepMomentum = true,
	Speed = 5,
	MaxHeight = 0,
	RopeLength = 5,
	Timer = 0,
	JumpOnDismount = true,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function Balloon.Run(scope: _T.Scope, utility: _T.Utility)
	local JumpButton = utility.JumpButton

	local balloonConfig = scope.instance
	if not balloonConfig then
		return
	end

	local balloonDispenser = balloonConfig.Parent
	local dispenser = balloonDispenser and balloonDispenser:FindFirstChild("Dispenser") :: BasePart
	local balloonTemplate = balloonDispenser and balloonDispenser:FindFirstChild("BalloonModel") :: Model
	local barTemplate = balloonDispenser and balloonDispenser:FindFirstChild("RopeBar") :: BasePart
	if not (balloonDispenser and dispenser and balloonTemplate and barTemplate) then
		local errorName = if balloonDispenser then balloonDispenser.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end

	scope:add(barTemplate)
	barTemplate.Parent = nil
	scope:add(balloonTemplate)
	balloonTemplate.Parent = nil
	balloonTemplate:RemoveTag("SkipObjectLoad")

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, balloonConfig, BALLOON_CONFIG_TEMPLATE):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, balloonConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, balloonConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()
	local timerGuiTemplate = balloonConfig:FindFirstChild("TimerGui") :: BillboardGui

	local soundsFolder = balloonDispenser:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = balloonDispenser
			return newSounds
		end)()

	scope:attach(balloonDispenser)

	----------------------------------------------------------------------------
	--> Dispense balloon
	local rideDebounce = {}
	local function dispense(attachTo: BasePart, isPlayer: boolean)
		if dispenser:GetAttribute("Activated") == false then
			return
		end

		if rideDebounce[attachTo] then
			return
		end

		local rideScope = scope:inherit()

		rideDebounce[attachTo] = true
		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][balloonDispenser] = "Balloon"

		------------------------------------------------------------------------
		--> Create balloon model
		local ropeBar = barTemplate:Clone()
		rideScope:attach(ropeBar)
		ropeBar.Color = dispenser.Color
		ropeBar.CFrame = attachTo.CFrame + attachTo.CFrame.UpVector * (attachTo.Size.Y / 2)
		ropeBar.Anchored = false
		ropeBar.Parent = balloonDispenser
		if isPlayer then
			utility.Character.carryPart(true, ropeBar, not configuration.HandleAnimation)
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachTo
			barWeld.Parent = ropeBar
		end

		local balloon = balloonTemplate:Clone()
		rideScope:attach(balloon)
		balloon.Parent = balloonDispenser

		local main = balloon:FindFirstChild("Main") :: BasePart
			or (function()
				local blankMain = Instance.new("Part")
				blankMain.Size = Vector3.zero
				blankMain.Transparency = 1
				blankMain.CanCollide = false
				blankMain.CFrame = balloon:GetPivot()
				blankMain.Parent = balloon
				return blankMain :: BasePart
			end)()
		main.Anchored = false

		local balloonAtt = main:FindFirstChild("BalloonAttachment") :: Attachment
			or (function()
				local newAtt = Instance.new("Attachment")
				newAtt.Parent = main
				return newAtt
			end)()

		local alignOrientation = main:FindFirstChildOfClass("AlignOrientation")
		if alignOrientation then
			alignOrientation.CFrame = main.CFrame
		end
		if main:IsA("Part") and main.TopSurface == Enum.SurfaceType.Hinge then
			main.TopSurface = Enum.SurfaceType.Smooth
		end

		if configuration.RopeLength > 0 then
			local ropeConstraint = ropeBar:FindFirstChildOfClass("RopeConstraint")
			if not (ropeConstraint and ropeConstraint.Attachment0) then
				scope:log({ `The {script.Name} script's rope constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup(true, true)
				return
			end

			balloon:PivotTo(CFrame.new(dispenser.Position) * balloon:GetPivot().Rotation)
			ropeConstraint.Color = dispenser.BrickColor
			ropeConstraint.Length = configuration.RopeLength
			ropeConstraint.Attachment1 = balloonAtt
		else
			local zeroLengthConstraint = ropeBar:FindFirstChild("ZeroLengthConstraint")
			if
				not (zeroLengthConstraint and zeroLengthConstraint:IsA("WeldConstraint") and zeroLengthConstraint.Part0)
			then
				scope:log({ `The {script.Name} script's zero length constraint is not set up properly.`, type = "warn" })
				rideScope:cleanup(true, true)
				return
			end

			local pivotPosition = ropeBar.Position + Vector3.yAxis * (main.Size.Y / 2)
			balloon:PivotTo(CFrame.new(pivotPosition) * balloon:GetPivot().Rotation)
			zeroLengthConstraint.Part1 = main
			zeroLengthConstraint.Enabled = true
		end

		local attachedToValue = Instance.new("ObjectValue")
		attachedToValue.Name = "_AttachedTo"
		attachedToValue.Value = attachTo
		attachedToValue.Parent = main

		utility.ClientObjects.scanFolder(rideScope, balloon)

		------------------------------------------------------------------------
		--> Inflate balloon
		utility.Functions.playSoundFromInstance(main, soundsFolder, "Inflate")
		for _, balloonPart in balloon:GetDescendants() do
			if not (balloonPart:IsA("BasePart") and balloonPart:GetAttribute("Inflate")) then
				continue
			end
			local originalSize = balloonPart.Size
			balloonPart.Size = Vector3.zero
			utility.Functions.tween(balloonPart, tweenConfiguration, { Size = originalSize })
		end

		------------------------------------------------------------------------
		--> Dismount function
		local humanoid = utility.Character.getHumanoid()
		local function dismountBalloon()
			rideScope:cleanup(true, true)

			if attachTo and not configuration.KeepMomentum then
				attachTo.AssemblyLinearVelocity = Vector3.zero
			end
			if isPlayer and humanoid then
				utility.Character.carryPart(false, ropeBar, not configuration.HandleAnimation)
				humanoid.PlatformStand = false
				
				if configuration.JumpOnDismount then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			utility.Functions.playSoundFromInstance(attachTo, soundsFolder, "Pop")

			if mountedCOs[attachTo] and mountedCOs[attachTo][balloonDispenser] then
				mountedCOs[attachTo][balloonDispenser] = nil
				if utility.Table.IsEmpty(mountedCOs[attachTo]) then
					mountedCOs[attachTo] = nil
				end
			end

			task.delay(TOUCH_COOLDOWN, function()
				rideDebounce[attachTo] = nil
			end)
		end

		------------------------------------------------------------------------
		--> Move balloon
		local maxForce = Vector3.one * 10000000
		local upVector = main.CFrame.UpVector
		if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1 then
			maxForce = Vector3.yAxis * 10000000
		end

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		linearVelocity.MaxAxesForce = maxForce
		linearVelocity.VectorVelocity = upVector * configuration.Speed
		linearVelocity.Attachment0 = balloonAtt
		linearVelocity.Parent = main

		------------------------------------------------------------------------
		--> Pop conditions
		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountBalloon()
			end))
		end

		local startTime = os.clock()
		local useTimer = configuration.Timer > 0
		local useMaxHeight = configuration.MaxHeight ~= 0

		local timerLabel
		if timerGuiTemplate and useTimer then
			local timerGui = timerGuiTemplate:Clone()
			timerGui.Parent = main
			timerGui.Enabled = true

			timerLabel = timerGui:FindFirstChild("TimerLabel") :: TextLabel
			if timerLabel then
				timerLabel.TextColor3 = main.Color
				timerLabel.Text = tostring(configuration.Timer)
			end
		end

		local rate = 1 / 60
		rideScope:spawn(function()
			while task.wait(rate) do
				debug.profilebegin("Balloon Checking")
				if not attachTo or not attachTo.Parent then
					dismountBalloon()
					break
				elseif not (mountedCOs[attachTo] and mountedCOs[attachTo][balloonDispenser]) then
					dismountBalloon()
					break
				end

				if not (configuration.DestroyWhenExpired or linearVelocity.VectorVelocity ~= Vector3.zero) then
					debug.profileend()
					continue
				end

				if useTimer then
					if timerLabel then
						local displayTime = math.ceil(configuration.Timer - (os.clock() - startTime))
						if tostring(displayTime) ~= timerLabel.Text then
							timerLabel.Visible = displayTime > 0
							timerLabel.Text = tostring(displayTime)
							utility.Functions.playSoundFromInstance(main, soundsFolder, "TimerTick")
						end
					end

					if os.clock() - startTime > configuration.Timer then
						if configuration.DestroyWhenExpired then
							dismountBalloon()
							break
						else
							linearVelocity.VectorVelocity = Vector3.zero
						end
					end
				end

				local isAbove = configuration.Speed > 0
					and main.Position.Y > dispenser.Position.Y + configuration.MaxHeight
				local isBelow = configuration.Speed < 0
					and main.Position.Y < dispenser.Position.Y + configuration.MaxHeight

				if useMaxHeight and (isAbove or isBelow) then
					if configuration.DestroyWhenExpired then
						dismountBalloon()
						break
					else
						linearVelocity.VectorVelocity = Vector3.zero
					end
				end

				debug.profileend()
			end
		end)
	end

	--> Activation
	scope:add(dispenser.Touched:Connect(function(touch)
		if not utility.ClientObjects.evaluateToucher(dispenser, touch, touchConfiguration) then
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
		dispense(attachTo, isPlayer)
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(dispenser, function(rootPart)
			dispense(rootPart, true)
		end))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[balloonDispenser] = function()
		local rootPart = utility.Character.getCharacter().rootPart
		if not rootPart then
			return
		end
		dispense(rootPart, true)
	end
	scope:add(function()
		cache[balloonDispenser] = nil
		cache = nil :: any
	end)
end

return Balloon
