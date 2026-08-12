--!strict
--!optimize 2
--@version turret-6.1.2
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type TurretHitData = {
	valid: boolean,
	hitPlayer: boolean?,
}

local HIT_TYPES: { [string]: TurretHitData } = {
	INVALID = { valid = false },
	VALID = { valid = true },
	VALID_PLAYER = { valid = true, hitPlayer = true },
}

local Turret = {
	CanQueue = true,
	RunOnStart = false,
}
local TURRET_CONFIG_TEMPLATE = {
	FireRate = 0.2,
	Damage = 5,
	Range = 50,
	Speed = 50,
	MaxLifetime = 15,
	DestroyOnTouch = true,
	BulletOffset = CFrame.identity,
	ActivatorCooldown = 1,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function Turret.Run(scope: _T.Scope, utility: _T.Utility)
	local turretConfig = scope.instance
	if not turretConfig then
		return
	end

	local turretModel = turretConfig.Parent
	if not turretModel then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, turretConfig, TURRET_CONFIG_TEMPLATE):ObserveChanges()

	--> Get objects and check for problems
	local turret = turretModel:FindFirstChild("Turret")
	if not turret or not turret:IsA("BasePart") then
		scope:log({
			"Turret is either missing its Turret part or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local bulletTemplate = turretModel:FindFirstChild("Bullet")
	if not bulletTemplate or not bulletTemplate:IsA("Model") or not bulletTemplate:HasTag("SkipObjectLoad") then
		scope:log({
			"Turret is either missing its Bullet model or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local touchConfiguration =
		Config.GetConfig(scope, turretConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

	scope:add(bulletTemplate)
	bulletTemplate.Parent = nil
	bulletTemplate:RemoveTag("SkipObjectLoad")

	local fireSoundTemplate = turret:FindFirstChild("Fire")
	if not fireSoundTemplate or not fireSoundTemplate:IsA("Sound") then
		scope:log({
			"Turret is either missing its Fire sound or has it set up incorrectly.",
			`Path: {turretModel:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Variables
	local player = Players.LocalPlayer

	--> Functions
	local function isValidHit(bullet: BasePart, hitPart: BasePart): TurretHitData
		if
			hitPart == turret
			or hitPart:HasTag("IgnoreBullets")
		then
			return HIT_TYPES.INVALID
		end

		local hitPlayer = Players:GetPlayerFromCharacter(hitPart.Parent)
		if utility.ClientObjects.evaluateToucher(bullet, hitPart, touchConfiguration) then
			if hitPlayer then
				return if hitPlayer == player then HIT_TYPES.VALID_PLAYER else HIT_TYPES.INVALID
			else
				return if hitPart.CanCollide then HIT_TYPES.VALID else HIT_TYPES.INVALID
			end
		else
			return if hitPart.CanCollide and not hitPlayer then HIT_TYPES.VALID else HIT_TYPES.INVALID
		end
	end

	local function fireBullet()
		local bulletScope = scope:inherit()

		local bulletModel = bulletScope:add(bulletTemplate:Clone())
		local mainPart = bulletModel.PrimaryPart
			or bulletModel:FindFirstChild("Bullet")
			or (function()
				local baseBullet = script.Bullet:Clone()
				baseBullet.Parent = bulletModel
				return baseBullet
			end)()

		local spawnPos = turret.CFrame * configuration.BulletOffset
		bulletModel:PivotTo(spawnPos)

		local mainAttachment = mainPart:FindFirstChildOfClass("Attachment")
			or (function()
				local attachment = Instance.new("Attachment")
				attachment.Parent = mainPart
				return attachment
			end)()

		local linearVelocity = mainPart:FindFirstChildOfClass("LinearVelocity")
			or (function()
				local velocity = Instance.new("LinearVelocity")
				velocity.ForceLimitsEnabled = false
				velocity.Parent = mainPart
				return velocity
			end)()

		linearVelocity.Attachment0 = mainAttachment
		linearVelocity.VectorVelocity = turret.CFrame.LookVector * configuration.Speed

		local alignOrientation = mainPart:FindFirstChildOfClass("AlignOrientation")
			or (function()
				local aligner = Instance.new("AlignOrientation")
				aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
				aligner.RigidityEnabled = true
				aligner.Parent = mainPart
				return aligner
			end)()

		alignOrientation.Attachment0 = mainAttachment
		alignOrientation.CFrame = turret.CFrame.Rotation

		local fireSound = fireSoundTemplate:Clone()
		fireSound.Parent = turret
		fireSound:Play()
		task.delay(fireSound.TimeLength / fireSound.PlaybackSpeed, function()
			fireSound:Destroy()
		end)

		mainPart.Anchored = false
		bulletModel.Parent = turretModel
		utility.ClientObjects.scanFolder(bulletScope, bulletModel)

		--- touch/damage handling ---
		local function cleanup()
			bulletScope:cleanup(true, true)
		end

		for _, bulletPart in mainPart:GetConnectedParts(true) do
			if not bulletPart:IsA("BasePart") then
				continue
			end

			bulletScope:add(bulletPart.Touched:Connect(function(hitPart: BasePart)
				local hitResult = isValidHit(bulletPart, hitPart)
				if not hitResult.valid then
					return
				end

				if hitResult.hitPlayer and bulletPart.Name == "Bullet" then
					utility.Character.takeDamage(configuration.Damage)
				end

				if configuration.DestroyOnTouch then
					cleanup()
				end
			end))
		end

		bulletScope:delay(configuration.MaxLifetime, cleanup)
	end

	--> Main functionality
	scope:attach(turretModel)

	-- passive firing
	scope:defer(function()
		local FALLBACK_RATE = 1 / 25
		while true do
			if configuration.FireRate <= 0 then
				--> If the firerate is below 0, wait the default rate instead
				task.wait(FALLBACK_RATE)
				continue
			end

			task.wait(1 / configuration.FireRate)
			if turret:GetAttribute("Activated") == false then
				continue
			end

			local distance = player:DistanceFromCharacter(turret.Position)
			if distance < configuration.Range then
				fireBullet()
			end
		end
	end)

	-- activator parts
	local activatorFolder = turretModel:FindFirstChild("Activators")
	if activatorFolder then
		local cooldownActive = false

		for _, activator in activatorFolder:GetChildren() do
			if not activator:IsA("BasePart") then
				continue
			end

			local activatorTouchConfig =
				Config.GetConfig(scope, activator:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
					:ObserveChanges()

			local function activateActivator()
				if cooldownActive then
					return
				end
				cooldownActive = true
				task.delay(configuration.ActivatorCooldown, function()
					cooldownActive = false
				end)

				if activator:GetAttribute("Activated") == false then
					return
				end

				fireBullet()
			end

			activator.Touched:Connect(function(hitPart: BasePart)
				if not utility.ClientObjects.evaluateToucher(activator, hitPart, activatorTouchConfig) then
					return
				end

				activateActivator()
			end)

			if activatorTouchConfig.canFlip then
				activator:AddTag("DoNotFlipPlayer")
				scope:add(utility.ClientObjects.bindToFlip(activator, activateActivator))
			end
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[turretModel] = fireBullet
	scope:add(function()
		cache[turretModel] = nil
		cache = nil :: any
	end)
end

return Turret
