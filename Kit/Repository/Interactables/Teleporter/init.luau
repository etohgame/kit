--!strict
--!optimize 2
--@version teleporter-6.0.0
--@creator mario_123456, synnwave
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

local localPlayer = Players.LocalPlayer
local DISABLE_COLLISION_PROPERTIES = {
	CollisionGroup = "NeverCollide",
	CanTouch = false,
} :: { [string]: any }
type savedProperties = { [BasePart]: { [string]: any } }

local Teleporter = {
	CanQueue = true,
	RunOnStart = false,
}

local TELEPORTER_CONFIG_TEMPLATE = {
	Instant = true,
	KeepVelocity = true,
	SeamlessTeleport = false,
	DisableCollision = false,
	Offset = CFrame.new(0, 3, 0),
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function Teleporter.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local teleporterConfig = scope.instance
	if not teleporterConfig then
		return
	end

	local teleporterModel = teleporterConfig.Parent
	if not teleporterModel then
		return
	end

	local teleporterParts = {} :: { BasePart }
	local destinationParts = {} :: { BasePart }
	for _, part in teleporterModel:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Name == "Destination" then
			table.insert(destinationParts, part)
		elseif part.Name == "Teleporter" then
			table.insert(teleporterParts, part)
		end
	end

	--> Get Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, teleporterConfig, TELEPORTER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, teleporterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, teleporterConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	local function getActiveDestinations()
		return utility.Table.Filter(destinationParts, function(destination)
			return destination:GetAttribute("Activated") ~= false
		end)
	end

	--> Main Functionality
	local isTeleporting = false
	local function teleport(teleporter: BasePart, part: BasePart, isPlayer: boolean)
		local activeDestinations = getActiveDestinations()
		if isTeleporting or teleporter:GetAttribute("Activated") == false or #activeDestinations <= 0 then
			return
		end

		isTeleporting = true
		task.defer(function()
			isTeleporting = false
		end)

		local savedPartProperties = {
			[part] = { Anchored = part.Anchored },
		} :: savedProperties
		if not configuration.KeepVelocity then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			savedPartProperties[part].AssemblyLinearVelocity = Vector3.zero
			savedPartProperties[part].AssemblyAngularVelocity = Vector3.zero
		end
		if configuration.DisableCollision then
			if isPlayer then
				for _, part in localPlayer.Character:GetChildren() do
					if not part:IsA("BasePart") or savedPartProperties[part] ~= nil then
						continue
					end
					savedPartProperties[part] = {}
				end
			end

			for part, properties in savedPartProperties do
				for property, value in DISABLE_COLLISION_PROPERTIES do
					properties[property] = utility.Property.getPropertySafe(part, property)
					utility.Property.setPropertySafe(part, property, value)
				end
			end
		end

		local transitionTime = if configuration.Instant then 0 else tweenConfiguration.Time
		local chosenDestination = activeDestinations[math.random(#activeDestinations)]
		local destinationCFrame = chosenDestination:GetPivot()
		local teleporterCFrame = teleporter:GetPivot()
		local targetCFrame = destinationCFrame * configuration.Offset

		local camera = Workspace.CurrentCamera
		local targetCameraCFrame
		if configuration.SeamlessTeleport then
			targetCFrame = destinationCFrame * teleporterCFrame:ToObjectSpace(part:GetPivot())
			if isPlayer then
				targetCameraCFrame = destinationCFrame * teleporterCFrame:ToObjectSpace(camera.CFrame)
			end
		end

		utility.Functions.playSoundFromInstance(chosenDestination, chosenDestination, "Teleport")
		if transitionTime > 0 then
			part.Anchored = true
			local tween = utility.Functions.tween(part, tweenConfiguration, { CFrame = targetCFrame })
			local oldCameraType
			if targetCameraCFrame then
				oldCameraType = camera.CameraType
				camera.CameraType = Enum.CameraType.Scriptable
				utility.Functions.tween(camera, tweenConfiguration, { CFrame = targetCameraCFrame })
			end

			tween.Completed:Wait()
			if oldCameraType then
				camera.CameraType = oldCameraType
			end
		else
			if targetCameraCFrame then
				camera.CFrame = targetCameraCFrame
			end

			part:PivotTo(targetCFrame)
		end

		for part, properties in savedPartProperties do
			for property, value in properties do
				utility.Property.setPropertySafe(part, property, value)
			end
		end
	end

	scope:attach(teleporterModel)
	for _, teleporter in teleporterParts do
		scope:add(teleporter.Touched:Connect(function(touchingPart: BasePart)
			if
				isTeleporting
				or teleporter:GetAttribute("Activated") == false
				or not utility.ClientObjects.evaluateToucher(teleporter, touchingPart, touchConfiguration)
			then
				return
			end

			local part: BasePart?
			local character = localPlayer.Character
			local isPlayer = false
			if touchingPart:IsDescendantOf(character) and character.PrimaryPart then
				isPlayer = true
				part = character.PrimaryPart
			elseif utility.ClientObjects.isPushbox(touchingPart) then
				part = touchingPart
			end
			if not (part and part.Parent) then
				return
			end

			teleport(teleporter, part, isPlayer)
		end))

		if touchConfiguration.canFlip then
			teleporter:AddTag("DoNotFlipPlayer")
			scope:add(utility.ClientObjects.bindToFlip(teleporter, function()
				teleport(teleporter, localPlayer.Character.PrimaryPart, true)
			end))
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[teleporterModel] = function()
		teleport(teleporterParts[1], localPlayer.Character.PrimaryPart, true)
	end
	scope:add(function()
		cache[teleporterModel] = nil
		cache = nil :: any
	end)
end

return Teleporter
