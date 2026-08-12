--!strict
--!optimize 2
--@version jumplauncher-6.1.0
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
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local UPDATE_INTERVAL = 1 / 60

local JumpLauncher = {
	CanQueue = true,
	RunOnStart = false,
}

local LAUNCHER_CONFIG_TEMPLATE
function JumpLauncher.Init(utility: _T.Utility)
	local Config = utility.Config
	LAUNCHER_CONFIG_TEMPLATE = {
		Cooldown = 0.25,
		Force = 60,
		SizeReduction = Vector3.one,
		Transparency = Config.Type.number,
	}
end

local player = Players.LocalPlayer
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {
		playerBuffering = false,
		boxBuffering = false,
		playerOccupied = false,
		occupiedBlocks = {},
	}

	local characterInstances = utility.Character.getCharacter()
	rootScope:add(utility.JumpButton.JumpEvent.Event:Connect(function(jumpState: boolean)
		local humanoid = characterInstances.humanoid
		cache.boxBuffering = jumpState
		if jumpState then
			if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall or cache.playerOccupied then
				cache.playerBuffering = true
			end
		else
			cache.playerBuffering = false
		end
	end))

	local function attachStateChanged(character: Model)
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			return
		end
		rootScope:add(humanoid.StateChanged:Connect(function(oldState, newState)
			if cache.playerBuffering and newState ~= Enum.HumanoidStateType.Freefall and not cache.playerOccupied then
				cache.playerBuffering = false
			end
		end))
	end

	attachStateChanged(characterInstances.character)
	rootScope:add(player.CharacterAdded:Connect(attachStateChanged))
	return cache
end

function JumpLauncher.Run(scope: _T.Scope, utility: _T.Utility)
	local launcherConfig = scope.instance
	if not launcherConfig then
		return
	end

	local jumpLauncher = launcherConfig.Parent
	if not jumpLauncher or not jumpLauncher:IsA("BasePart") then
		return
	end

	--> Get Cache
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	local characterInstances = utility.Character.getCharacter()

	--> Get Configurations
	local originalTransparency = jumpLauncher.Transparency
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, launcherConfig, LAUNCHER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, launcherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	--> Model Setup
	local soundsFolder = jumpLauncher:FindFirstChild("Sounds")
		or (function()
			local sounds = Instance.new("Folder")
			sounds.Parent = jumpLauncher
			return sounds
		end)()

	local bounceParticle: ParticleEmitter?
	local particleAttachment = jumpLauncher:FindFirstChild("Particles")
	if particleAttachment then
		bounceParticle = particleAttachment:FindFirstChild("BounceParticle") :: ParticleEmitter
	end

	local jumpGroup = Instance.new("Model")
	jumpGroup.Parent = jumpLauncher.Parent
	jumpLauncher.Parent = jumpGroup

	local invisible = jumpLauncher:HasTag("Invisible")

	local hitbox = jumpLauncher:Clone()
	hitbox.Parent = jumpGroup
	hitbox.Transparency = if invisible then 1 else 0.95
	hitbox.Material = Enum.Material.Neon
	hitbox.CanCollide = false
	hitbox.Name = "JumpLauncherHitbox"
	hitbox:ClearAllChildren()

	local hitboxWeld = Instance.new("WeldConstraint")
	hitboxWeld.Part0 = hitbox
	hitboxWeld.Part1 = jumpLauncher
	hitboxWeld.Parent = hitbox
	hitbox.Anchored = false

	jumpLauncher.Size -= configuration.SizeReduction

	local jumpCooldown = false
	scope:attach(jumpLauncher)
	local touchScope = scope:inherit()
	local function enterJumpLauncher(touch)
		if cache.occupiedBlocks[jumpLauncher] or jumpCooldown or jumpLauncher:GetAttribute("Activated") == false then
			return
		end

		if not utility.ClientObjects.evaluateToucher(jumpLauncher, touch, touchConfiguration) then
			return
		end

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.CollisionGroup = ""

		local isPlayer = false
		local isBox = false
		if touch:IsDescendantOf(characterInstances.character) then
			local hitbox = utility.Character.getHitbox("StaticWholeBody", overlapParams)
			if not table.find(hitbox, touch) then
				return
			end

			isPlayer = true
			cache.playerOccupied = true
		elseif utility.ClientObjects.isPushbox(touch) then
			isBox = true
			overlapParams:AddToFilter(touch)
		end

		if not (isPlayer or isBox) then
			return
		end

		local launchPart = if isPlayer then characterInstances.rootPart else touch
		cache.occupiedBlocks[jumpLauncher] = true

		utility.Functions.playSoundFromInstance(jumpLauncher, soundsFolder, "Tick")
		utility.Functions.tween(
			jumpLauncher,
			0.1,
			{ Size = hitbox.Size - (configuration.SizeReduction / 8) },
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)

		touchScope:spawn(function()
			while true do
				debug.profilebegin("Jump Launcher Query")
				if (isPlayer and cache.playerBuffering) or (isBox and cache.boxBuffering) and not jumpCooldown then
					--> Jump
					if isPlayer then
						cache.playerBuffering = false
					elseif isBox then
						cache.boxBuffering = false
					end
					jumpCooldown = true

					utility.Functions.playSoundFromInstance(jumpLauncher, soundsFolder, "Bounce")
					local targetTransparency = if invisible
						then 1
						else configuration.Transparency or originalTransparency
					jumpLauncher.Transparency = if invisible then 1 else targetTransparency / 4
					utility.Functions.tween(jumpLauncher, 0.5, { Transparency = targetTransparency })
					if bounceParticle then
						bounceParticle:Emit(1)
					end

					local maxForce = Vector3.one * 40000
					local upVector = jumpLauncher.CFrame.UpVector
					if math.abs(upVector.X) < 0.1 and math.abs(upVector.Z) < 0.1 then
						maxForce = Vector3.yAxis * 40000
					end

					local velocityAttachment = Instance.new("Attachment")
					local linearVelocity = Instance.new("LinearVelocity")
					linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
					linearVelocity.MaxAxesForce = maxForce
					linearVelocity.VectorVelocity = upVector * configuration.Force
					linearVelocity.Attachment0 = velocityAttachment

					velocityAttachment.Parent = launchPart
					linearVelocity.Parent = launchPart
					task.delay(0.125, function()
						linearVelocity:Destroy()
						velocityAttachment:Destroy()
					end)
					task.delay(configuration.Cooldown, function()
						jumpCooldown = false
						local overlapParts = Workspace:GetPartsInPart(hitbox, overlapParams)
						if #overlapParts >= 1 then
							enterJumpLauncher(touch)
						end
					end)

					debug.profileend()
					break
				else
					--> Check if the player is within the zone
					local overlapParts = Workspace:GetPartsInPart(hitbox, overlapParams)
					if #overlapParts < 1 then
						debug.profileend()
						break
					end
				end
				debug.profileend()
				task.wait(UPDATE_INTERVAL)
			end

			utility.Functions.tween(
				jumpLauncher,
				0.1,
				{ Size = hitbox.Size - configuration.SizeReduction },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)

			cache.occupiedBlocks[jumpLauncher] = nil
			if isPlayer then
				cache.playerOccupied = false
			end

			touchScope:cleanup(true)
		end)
	end
	scope:add(hitbox.Touched:Connect(enterJumpLauncher))
end

return JumpLauncher
