--!strict
--!optimize 2
--@version attacher-6.1.3
--@creator aamo_s
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

local Attacher = {
	CanQueue = true,
	RunOnStart = false,
}

local LIMB_MAP = {
	[Enum.Limb.Head] = "Head",
	[Enum.Limb.Torso] = "HumanoidRootPart",
	[Enum.Limb.LeftArm] = "Left Arm",
	[Enum.Limb.RightArm] = "Right Arm",
	[Enum.Limb.LeftLeg] = "Left Leg",
	[Enum.Limb.RightLeg] = "Right Leg",
}

local BANNED_STATES = {
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.StrafingNoPhysics] = true,
	[Enum.HumanoidStateType.RunningNoPhysics] = true,
}

local ATTACHER_CONFIG_TEMPLATE
function Attacher.Init(utility: _T.Utility)
	local Config = utility.Config
	ATTACHER_CONFIG_TEMPLATE = {
		AttachUsingAlign = false,
		Cooldown = 0.5,
		CleanDelay = 0,
		DismountState = Config.Type.Enum(Enum.HumanoidStateType.Jumping),
		DismountStateEnabled = true,
		Offset = CFrame.new(0, 0, -5),
		WeldToLimb = Config.Type.Enum(Enum.Limb.Torso),
	}
end

local function getLimb(character: Instance?, hitPart: BasePart, limb: Enum.Limb): BasePart?
	if not character or not limb then
		return
	end
	if limb == Enum.Limb.Unknown then
		return nil
	end

	local limbName = LIMB_MAP[limb]
	local limbPart = character:FindFirstChild(limbName)
	if not limbPart or not limbPart:IsA("BasePart") then
		return
	end
	return limbPart
end

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function Attacher.Run(scope: _T.Scope, utility: _T.Utility)
	local JumpButton = utility.JumpButton
	local attacherConfig = scope.instance
	if not attacherConfig then
		return
	end

	local model = attacherConfig.Parent
	if not model then
		return
	end

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local baseModel = model:FindFirstChild("WeldModel")
	if not baseModel or not baseModel:IsA("Model") then
		scope:log({
			"Attacher is missing the WeldModel.",
			`Path: {model:GetFullName()}`,
			type = "warn",
		})

		return
	end

	if not baseModel:HasTag("SkipObjectLoad") then
		scope:log({
			"Attacher is missing its 'SkipObjectLoad' tag.",
			`Path: {model:GetFullName()}`,
			type = "warn",
		})
		return
	end
	scope:add(baseModel)
	baseModel.Parent = nil
	baseModel:RemoveTag("SkipObjectLoad")

	if not baseModel.PrimaryPart then
		scope:log({
			"Attacher is missing the PrimaryPart on WeldModel.",
			`Path: {baseModel:GetFullName()}`,
			type = "warn",
		})

		return
	end

	--> Get Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, attacherConfig, ATTACHER_CONFIG_TEMPLATE):ObserveChanges()
	if BANNED_STATES[configuration.DismountState] then
		scope:log({
			"Attacher is using a banned state type.",
			`Path: {attacherConfig:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local touchConfiguration =
		Config.GetConfig(scope, attacherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	--> Main Functionality
	local touchDebounce = {}
	local function attach(trigger: Instance, hitPart: BasePart)
		if trigger:GetAttribute("Activated") == false then
			return
		end

		local characterInstances = utility.Character.getCharacter()
		local character = characterInstances.character
		local humanoid = characterInstances.humanoid
		local rootPart = characterInstances.rootPart
		if not rootPart or not humanoid or humanoid.Health <= 0 or touchDebounce[trigger] then
			return
		end

		local attachTo = nil
		if hitPart:IsDescendantOf(character) then
            if table.find(utility.Character.getHitbox("WholeBody"), hitPart) then
				attachTo = getLimb(character, hitPart, configuration.WeldToLimb)
			end
		else
			attachTo = hitPart
		end
		if not attachTo then
			return
		end

		local attachScope = scope:inherit()
		touchDebounce[trigger] = true
		if not mountedCOs[attachTo] then
			mountedCOs[attachTo] = {}
		end
		mountedCOs[attachTo][model] = "Attacher"

		local weldModel = attachScope:add(baseModel:Clone())

		local primaryPart = weldModel.PrimaryPart :: BasePart
		local connection: RBXScriptConnection? = nil

		if not configuration.AttachUsingAlign then
			local weldConstraint = Instance.new("WeldConstraint")
			weldConstraint.Part0 = attachTo
			weldConstraint.Part1 = primaryPart
			weldConstraint.Parent = primaryPart

			weldModel:PivotTo(attachTo.CFrame * configuration.Offset)
		else
			local bodyAttachment = attachScope:add(Instance.new("Attachment"))
			bodyAttachment.CFrame = configuration.Offset
			bodyAttachment.Name = "AttacherAttachment"
			bodyAttachment.Parent = attachTo

			local primaryPartAttachment = attachScope:add(Instance.new("Attachment"))
			primaryPartAttachment.Parent = primaryPart

			local positionExists = trigger:FindFirstChildOfClass("AlignPosition")
			local orientationExists = trigger:FindFirstChildOfClass("AlignOrientation")

			local alignPosition = Instance.fromExisting(positionExists or script.DefaultAlignPosition)
			local alignOrientation = Instance.fromExisting(orientationExists or script.DefaultAlignOrientation)

			alignPosition.Attachment0 = primaryPartAttachment
			alignPosition.Attachment1 = bodyAttachment
			alignOrientation.Attachment0 = primaryPartAttachment
			alignOrientation.Attachment1 = bodyAttachment

			alignPosition.Parent = primaryPartAttachment
			alignOrientation.Parent = primaryPartAttachment

			weldModel:PivotTo(bodyAttachment.WorldCFrame)
		end

		primaryPart.Anchored = false
		weldModel.Parent = model
		utility.ClientObjects.scanFolder(attachScope, weldModel)

		local function cleanup()
			attachScope:cleanup(true)
		end

		local function dismount()
			if mountedCOs[attachTo] and mountedCOs[attachTo][model] then
				mountedCOs[attachTo][model] = nil
				if utility.Table.IsEmpty(mountedCOs[attachTo]) then
					mountedCOs[attachTo] = nil
				end
			end

			if connection then
				connection:Disconnect()
				connection = nil
			end

			if configuration.CleanDelay <= 0 then
				cleanup()
			else
				scope:delay(configuration.CleanDelay, cleanup)
			end

			scope:delay(configuration.Cooldown, function()
				touchDebounce[trigger] = nil
			end)
		end

		if configuration.DismountStateEnabled then
			connection = humanoid.StateChanged:Connect(function(_, new)
				if new == configuration.DismountState then
					dismount()
				end
			end)
		end

		attachScope:spawn(function()
			while task.wait(1 / 60) do
				debug.profilebegin("Attacher Checking")

				if not attachTo or not attachTo.Parent then
					dismount()
					break
				elseif not (mountedCOs[attachTo] and mountedCOs[attachTo][model]) then
					dismount()
					break
				elseif humanoid and humanoid:GetState() == Enum.HumanoidStateType.Dead then
					dismount()
					break
				end

				debug.profileend()
			end
		end)
	end

	--> Activation
	for _, trigger in model:GetChildren() do
		if not trigger:IsA("BasePart") or trigger.Name ~= "Trigger" then
			continue
		end
		scope:attach(trigger)
		scope:add(trigger.Touched:Connect(function(hitPart)
			if not utility.ClientObjects.evaluateToucher(trigger, hitPart, touchConfiguration) then
				return
			end

			attach(trigger, hitPart)
		end))

		if touchConfiguration.canFlip then
			scope:add(utility.ClientObjects.bindToFlip(trigger, function(rootPart)
				attach(trigger, rootPart)
			end))
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[model] = function()
		local rootPart = utility.Character.getCharacter().rootPart
		if not rootPart then
			return
		end
		attach(model:FindFirstChild("Trigger") or model, rootPart)
	end
	scope:add(function()
		cache[model] = nil
		cache = nil :: any
	end)
end

return Attacher
