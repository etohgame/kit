--!strict
--!optimize 2
--@version vine-6.1.3
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

local Vine = {
	CanQueue = true,
	RunOnStart = false,
}

local VINE_CONFIG_TEMPLATE = {
	HandleAnimation = true,
	AllowJumpDismount = true,
	KeepMomentum = true,
	RespawnTime = 1,
	JumpOnDismount = true,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function Vine.Run(scope: _T.Scope, utility: _T.Utility)
	local JumpButton = utility.JumpButton
	local vineConfig = scope.instance
	if not vineConfig or not vineConfig.Parent then
		return
	end

	local vine = vineConfig.Parent
	local vinePart = vine:FindFirstChild("VinePart") :: BasePart
	local attachmentPart = vine:FindFirstChild("AttachmentPart") :: BasePart
	local constraintTemplate = vine:FindFirstChild("VineConstraint")
	local barTemplate = vine:FindFirstChild("RopeBar") :: BasePart
	if not (vinePart and attachmentPart and constraintTemplate and barTemplate) then
		local errorName = if vine then vine.Name else script.Name
		scope:log({ errorName .. " is missing one or more critical parts and cannot function.", type = "warn" })
		return
	end

	scope:add(barTemplate)
	barTemplate.Parent = nil

	if not constraintTemplate:IsA("Constraint") then
		scope:log({ vine.Name .. " has an invalid vine constraint.", type = "warn" })
		return
	end

	local player = Players.LocalPlayer

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, vineConfig, VINE_CONFIG_TEMPLATE):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, vineConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, vineConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG):ObserveChanges()

	local soundsFolder = vine:FindFirstChild("Sounds")
		or (function()
			local newSounds = Instance.new("Folder")
			newSounds.Parent = vine
			return newSounds
		end)()
	local particleEmitter = vinePart:FindFirstChild("RespawnParticle") :: ParticleEmitter

	local defaultTransparency = vinePart.Transparency
	local returnDefaultTags = { "Invisible", "IgnoreTransparency", "IgnoreAll" }
	local function getDefaultTransparency()
		for _, tag in returnDefaultTags do
			if vinePart:HasTag(tag) then
				return defaultTransparency
			end
		end

		if vinePart:HasTag("ButtonActivated") then
			if vinePart:GetAttribute("Activated") then
				return utility.Property.assureAttribute(vinePart, "SetTransparency", 0)
			else
				return if vinePart:HasTag("FullHide") then 1 else 0.6
			end
		else
			return defaultTransparency
		end
	end

	scope:attach(vine)

	----------------------------------------------------------------------------
	--> Mount vine
	local respawnTween
	local rideDebounce = false
	local rideScope = scope:inherit()

	local function ride(attachedRoot: BasePart, isPlayer: boolean)
		if vinePart:GetAttribute("Activated") == false or rideDebounce then
			return
		end

		rideDebounce = true
		if not mountedCOs[attachedRoot] then
			mountedCOs[attachedRoot] = {}
		end
		mountedCOs[attachedRoot][vine] = "Vine"

		utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Grab")

		if respawnTween then
			respawnTween:Cancel()
		end
		vinePart.Transparency = 1

		----------------------------------------------------------------------------
		--> Attachment
		local ropeBar = barTemplate:Clone()
		rideScope:attach(ropeBar)
		ropeBar.Color = attachmentPart.Color
		ropeBar.CFrame = attachedRoot.CFrame + attachedRoot.CFrame.UpVector * (attachedRoot.Size.Y / 2)
		ropeBar.Anchored = false
		ropeBar.Parent = vine
		if isPlayer then
			utility.Character.carryPart(true, ropeBar, not configuration.HandleAnimation)
		else
			local barWeld = Instance.new("WeldConstraint")
			barWeld.Part0 = ropeBar
			barWeld.Part1 = attachedRoot
			barWeld.Parent = ropeBar
		end

		local barAttachment = ropeBar:FindFirstChildOfClass("Attachment")
			or (function()
				local newAtt = Instance.new("Attachment")
				newAtt.Parent = ropeBar
				return newAtt
			end)()

		local topAttachment = attachmentPart:FindFirstChild("VineAttachment") :: Attachment
			or (function()
				local newAtt = Instance.new("Attachment")
				newAtt.Name = "VineAttachment"
				newAtt.CFrame *= CFrame.Angles(0, 0, math.pi * 0.5)
				newAtt.Parent = attachmentPart
				return newAtt
			end)()

		local vineConstraint = constraintTemplate:Clone()
		vineConstraint.Color = attachmentPart.BrickColor
		vineConstraint.Attachment0 = barAttachment
		vineConstraint.Attachment1 = topAttachment
		vineConstraint.Enabled = true
		vineConstraint.Parent = ropeBar

		------------------------------------------------------------------------
		--> Dismount function
		local humanoid = utility.Character.getHumanoid()
		local function dismountVine()
			rideScope:cleanup(true)

			if attachedRoot and not configuration.KeepMomentum then
				attachedRoot.AssemblyLinearVelocity = Vector3.zero
			end
			if isPlayer and humanoid then
				utility.Character.carryPart(false, ropeBar, not configuration.HandleAnimation)
				humanoid.PlatformStand = false
				if configuration.JumpOnDismount then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
				utility.Functions.playSoundFromInstance(attachedRoot, soundsFolder, "Jump")
			end

			if mountedCOs[attachedRoot] and mountedCOs[attachedRoot][vine] then
				mountedCOs[attachedRoot][vine] = nil
				if utility.Table.IsEmpty(mountedCOs[attachedRoot]) then
					mountedCOs[attachedRoot] = nil
				end
			end

			task.delay(configuration.RespawnTime, function()
				respawnTween =
					utility.Functions.tween(vinePart, tweenConfiguration, { Transparency = getDefaultTransparency() })

				if particleEmitter then
					particleEmitter.Enabled = true
					respawnTween.Completed:Once(function()
						particleEmitter.Enabled = false
					end)
				end

				rideDebounce = false
			end)
		end

		if configuration.AllowJumpDismount then
			rideScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
				if not isPressed then
					return
				end
				dismountVine()
			end))
		end

		rideScope:spawn(function()
			while task.wait() do
				debug.profilebegin("Vine Checking")
				if not attachedRoot or not attachedRoot.Parent then
					dismountVine()
					break
				elseif not (mountedCOs[attachedRoot] and mountedCOs[attachedRoot][vine]) then
					dismountVine()
					break
				end
				debug.profileend()
			end
		end)
	end

	--> Activation
	scope:add(vinePart.Touched:Connect(function(touch)
		if not utility.ClientObjects.evaluateToucher(vinePart, touch, touchConfiguration) then
			return
		end

		local characterInstances = utility.Character.getCharacter()
		local rootPart = characterInstances.rootPart
		if not rootPart then
			return
		end

		local isPlayer = table.find(utility.Character.getHitbox("StaticWholeBody"), touch) ~= nil
		local isBox = utility.ClientObjects.isPushbox(touch, true)
		if not (isPlayer or isBox) then
			return
		end

		local attachedRoot = if isPlayer then rootPart else touch
		ride(attachedRoot, isPlayer)
	end))

	if touchConfiguration.canFlip then
		vinePart:AddTag("DoNotFlipPlayer")
		scope:add(utility.ClientObjects.bindToFlip(vinePart, function(rootPart)
			ride(rootPart, true)
		end))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[vine] = function()
		local rootPart = utility.Character.getCharacter().rootPart
		if not rootPart then
			return
		end
		ride(rootPart, true)
	end
	scope:add(function()
		cache[vine] = nil
		cache = nil :: any
	end)
end

return Vine
