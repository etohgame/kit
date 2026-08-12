--!strict
--!optimize 2
--@version onewayplatform-6.0.0
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

type PlatformData = {
	Active: boolean,
	Offset: CFrame,
	SetActive: boolean,
	Parts: { BasePart },
	ActiveTransparency: number?,
	InactiveTransparency: number?,
	OriginalTransparency: number,
}
type PlatformCache = { [BasePart]: PlatformData }

local OneWayPlatform = {
	CanQueue = true,
	RunOnStart = false,
}

local ACTIVE_KEY = "OneWayPlatform_Activated"
local ACTIVE_CHECK_IGNORES = { [ACTIVE_KEY] = true }
local PLATFORM_CONFIG_TEMPLATE
function OneWayPlatform.Init(utility: _T.Utility)
	local Config = utility.Config
	PLATFORM_CONFIG_TEMPLATE = {
		SetActivated = true,
		Offset = CFrame.identity,
		ActiveTransparency = Config.Type.number,
		InactiveTransparency = Config.Type.number,
		ActivateConnectedParts = false,
	}
end

local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: PlatformCache

	local characterInstances = utility.Character.getCharacter()
	local setInstanceActive = utility.ClientObjects.setInstanceActive
	local isTableEmpty = utility.Table.IsEmpty
	rootScope:add(RunService.Stepped:Connect(function()
		debug.profilebegin("Handle OneWayPlatforms")

		local rootPart = characterInstances.rootPart
		if not rootPart or isTableEmpty(cache) then
			debug.profileend()
			return
		end

		local characterPivot = rootPart:GetPivot()
		for part, data in cache do
			local partPivot = part:GetPivot()
			local upVector = partPivot.UpVector
			local look = CFrame.lookAt(
				(partPivot * data.Offset).Position,
				(characterPivot * CFrame.new(0, -math.sign(upVector:Dot(Vector3.yAxis)), 0)).Position
			).LookVector

			local active = data.Active and upVector:Dot(look) > 0
			local originalTransparency = data.OriginalTransparency
			local transparency = if active
				then data.ActiveTransparency or originalTransparency
				else data.InactiveTransparency or originalTransparency

			for _, otherPart in data.Parts do
				if otherPart.CanCollide ~= active then
					otherPart.CanCollide = active
					if otherPart.Transparency ~= transparency then
						otherPart.Transparency = transparency
					end

					if data.SetActive then
						setInstanceActive(rootScope, otherPart, ACTIVE_KEY, active)
					end
				end
			end
		end

		debug.profileend()
	end))

	return cache
end

function OneWayPlatform.Run(scope: _T.Scope, utility: _T.Utility)
	local platformConfig = scope.instance
	if not platformConfig or not platformConfig:IsDescendantOf(Workspace) then
		return
	end

	local platform = platformConfig.Parent
	if not platform or not platform:IsA("BasePart") then
		return
	end

	local clientObjectUtil = utility.ClientObjects
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	local config = utility.Config.GetConfig(scope, platformConfig, PLATFORM_CONFIG_TEMPLATE)

	local parts = { platform }
	if config.ActivateConnectedParts then
		for _, part in platform:GetConnectedParts(true) do
			table.insert(parts, part)
		end
	end

	local platformData: PlatformData = {
		Active = clientObjectUtil.isInstanceActive(scope, platform, ACTIVE_CHECK_IGNORES),
		Offset = CFrame.new(Vector3.yAxis * (platform.Size.Y * 0.5)) * config.Offset,
		SetActive = config.SetActivated,
		Parts = parts,
		ActiveTransparency = config.ActiveTransparency,
		InactiveTransparency = config.InactiveTransparency,
		OriginalTransparency = platform.Transparency,
	}
	cache[platform] = platformData
	scope:attach(platform)
	scope:add(
		function()
			cache[platform] = nil
			cache = nil :: any
		end,
		platform:GetPropertyChangedSignal("Size"):Connect(function()
			platformData.Offset = CFrame.new(Vector3.yAxis * (platform.Size.Y * 0.5)) * config.Offset
		end)
	)

	-- these get automatically added to the scope, no need to add it here
	clientObjectUtil.listenInstanceActive(scope, platform, ACTIVE_CHECK_IGNORES, function(isActive)
		platformData.Active = isActive
	end)
end

return OneWayPlatform
