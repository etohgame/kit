--!strict
--!optimize 2
--@version bouncepad-6.0.1
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

local BouncePad = {
	CanQueue = true,
	RunOnStart = false,
}

local PAD_CONFIG_TEMPLATE
function BouncePad.Init(utility: _T.Utility)
	local Config = utility.Config
	PAD_CONFIG_TEMPLATE = {
		Power = 100,
		Cooldown = 0.05,
		RelativeForce = false,
	}
end

function BouncePad.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local bouncePadConfig = scope.instance
	if not bouncePadConfig then
		return
	end

	local bouncePad = bouncePadConfig.Parent
	if not bouncePad or not bouncePad:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, bouncePadConfig, PAD_CONFIG_TEMPLATE):ObserveChanges()

	local touchConfiguration =
		Config.GetConfig(scope, bouncePadConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, bouncePadConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	scope:attach(bouncePad)

	--> Variables
	local player = Players.LocalPlayer
	local bouncePadColor = bouncePad.Color
	local cooldownActive = false

	--> Functions
	local function bounce(part: BasePart)
		if cooldownActive or part.Anchored or bouncePad:GetAttribute("Activated") == false then
			return
		end

		cooldownActive = true
		task.delay(configuration.Cooldown, function()
			cooldownActive = false
		end)

		if Players:GetPlayerFromCharacter(part.Parent) == player then
			part = player.Character.PrimaryPart

			-- fix velocity sometimes being weird
			local humanoid = utility.Character.getHumanoid()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end
		end

		if configuration.RelativeForce then
			part.AssemblyLinearVelocity = -bouncePad.CFrame.RightVector * configuration.Power
		else
			local oldVel = part.AssemblyLinearVelocity
			part.AssemblyLinearVelocity = Vector3.new(oldVel.X, configuration.Power, oldVel.Z)
		end

		--> VFX & SFX
		local particleAttachment = bouncePad:FindFirstChild("ParticleAtt")
		local bounceParticle = (particleAttachment or bouncePad):FindFirstChild("BounceParticle")
		if bounceParticle and bounceParticle:IsA("ParticleEmitter") then
			bounceParticle:Emit(1)
		end
		utility.Functions.playSoundFromInstance(bouncePad, bouncePadConfig, "BounceSound")

		local h, s, v = bouncePadColor:ToHSV()
		bouncePad.Color = Color3.fromHSV(h, math.clamp(s + 0.125, 0, 1), math.clamp(v + 0.25, 0, 1))
		utility.Functions.tween(bouncePad, tweenConfiguration, { Color = bouncePadColor })
	end

	--> Main functionality
	scope:add(bouncePad.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(bouncePad, toucher, touchConfiguration) then
			return
		end

		bounce(toucher)
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(bouncePad, function(rootPart)
			bounce(rootPart)
		end))
	end

	--> Fix button activated bouncepads
	if bouncePad:GetAttribute("ColorOverride") == nil then
		bouncePad:SetAttribute("ColorOverride", bouncePadColor)
	end
end

return BouncePad
