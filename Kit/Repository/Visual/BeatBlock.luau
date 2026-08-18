--!strict
--!optimize 2
--@version beatblock-6.1.2
--@creator mario_123456, synnwave, Camille
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

local BeatBlock = {
	CanQueue = true,
	RunOnStart = false,
}

local BEATBLOCK_CONFIG_TEMPLATE = {
	ChangeCanTouch = true,
	Indicator = true,
	IndicatorSize = Vector3.new(3, 3, 3),
	IndicatorScaleMultiplier = 1,
	MaterialIndicator = Enum.Material.SmoothPlastic,

	OffCanCollide = false,
	OffTransparency = 0.5,
	OffCanTouch = false,

	OnCanCollide = true,
	OnTransparency = 1,
	OnCanTouch = true,

	Interval = 1,
	IndicatorInterval = 0.5,

	ToggleChildren = false,
}
local MUSIC_SYNC_CONFIG_TEMPLATE = {
	ZoneName = "",
	SyncEnabled = false,
}

local REFRESH_RATE = 1 / 60

type Block = {
	part: BasePart,
	size: Vector3,
	material: Enum.Material,
	children: {Instance},
}

local AFFECTED_CHILDREN: {[string]: string} = {
	Decal = "Transparency",
	Texture = "Transparency",
	SelectionBox = "Transparency",
	SelectionSphere = "Transparency",

	SurfaceGui = "Enabled",
	BillboardGui = "Enabled",
	Beam = "Enabled",
	ParticleEmitter = "Enabled",
	Fire = "Enabled",
	Sparkles = "Enabled",
	Smoke = "Enabled",
	Trail = "Enabled",
	PointLight = "Enabled",
	SpotLight = "Enabled",
	SurfaceLight = "Enabled",
	Highlight = "Enabled",
}

local musicManager
local localPlayer = Players.LocalPlayer
function BeatBlock.Run(scope: _T.Scope, utility: _T.Utility)
	local beatblockConfig = scope.instance
	if not beatblockConfig then
		return
	end

	local folder = beatblockConfig.Parent
	if not folder or not folder:IsA("Folder") then
		return
	end

	local propertyUtil = utility.Property

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, beatblockConfig, BEATBLOCK_CONFIG_TEMPLATE):ObserveChanges()
	local musicSyncConfig = beatblockConfig:FindFirstChild("MusicSyncConfiguration")
	local syncConfiguration = Config.GetConfig(scope, musicSyncConfig, MUSIC_SYNC_CONFIG_TEMPLATE):ObserveChanges()

	local syncData
	if syncConfiguration.SyncEnabled then
		local syncPointer = utility.Instance.getPointer(musicSyncConfig:FindFirstChild("Sync"))
		if syncPointer then
			syncData = utility.SongTime.BuildSyncCache(require(syncPointer) :: any)
		end
	end

	local beatblockTable: { [number]: { Block } } = {}
	local tableList = 0

	local function getPartChildren(part: BasePart): {Instance}
		local children = {}

		for _, child in part:GetChildren() do
			if AFFECTED_CHILDREN[child.ClassName] then
				table.insert(children, child)
			end
		end

		return children
	end

	for _, part in folder:GetDescendants() do
		local positionNumber = tonumber(part.Name:match("%d+"))
		if not (part:IsA("BasePart") and not (positionNumber == nil)) then
			continue
		end

		part.CanCollide = configuration.OffCanCollide
		part.Transparency = configuration.OffTransparency

		if not beatblockTable[positionNumber] then
			beatblockTable[positionNumber] = {}
			tableList += 1
		end

		-- get children

		local block: Block = {
			part = part,
			size = part.Size,
			material = part.Material,
			children = getPartChildren(part),
		}

		table.insert(beatblockTable[positionNumber], block)
	end

	local sound = beatblockConfig:FindFirstChild("DingSound") or script.DefaultDingSound
	local function playSound(partList: { Block })
		if sound.TimeLength <= 0 or sound.Volume <= 0 then
			return
		end
		
		local closest = {}
		for _, part in partList do
			local distance = localPlayer:DistanceFromCharacter(part.part.Position)
			if distance < (closest[1] or math.huge) then
				closest = { distance, part }
			end
		end
		
		local thisSound = sound:Clone()
		thisSound.Parent = closest[2].part
		thisSound:Play()
		task.delay(thisSound.TimeLength / thisSound.PlaybackSpeed, function()
			thisSound:Destroy()
		end)
	end

	local function displayNext(nextIndex: number)
		local parts = beatblockTable[nextIndex]
		if not parts or not configuration.Indicator then
			return
		end

		for _, data in parts do
			local part = data.part
			part.Size = if configuration.IndicatorScaleMultiplier ~= 1
				then data.size * configuration.IndicatorScaleMultiplier
				else configuration.IndicatorSize
			part.CanCollide = configuration.OffCanCollide
			part.Transparency = configuration.OffTransparency
			part.Material = configuration.MaterialIndicator
		end
	end

	local function toggleBeatBlock(index: number)
		for i, parts in beatblockTable do
			local activated = i == index
			if activated then
				playSound(parts)
			end

			for _, data in parts do
				local part = data.part
				part.Material = data.material
				part.Size = data.size
				part.CanCollide = if activated then configuration.OnCanCollide else configuration.OffCanCollide
				part.CanTouch = if activated then configuration.OnCanTouch else configuration.OffCanTouch
				part.Transparency = if activated then configuration.OnTransparency else configuration.OffTransparency

				if configuration.ToggleChildren then
					for _, child in data.children do
						local affectedProperty = AFFECTED_CHILDREN[child.ClassName]
						local value: any

						if affectedProperty == "Transparency" then
							value = if activated then configuration.OnTransparency else configuration.OffTransparency
						else
							value = activated
						end

						if value ~= nil then
							propertyUtil.setPropertySafe(child, affectedProperty, value)
						end
					end
				end
			end
		end
	end

	local totalBeats = #beatblockTable
	scope:spawn(function()
		if syncData then
			-- Music Sync mode enabled
			local backgroundMusic = ReplicatedStorage:WaitForChild("Background Music")
			if not musicManager then
				musicManager = require(backgroundMusic:WaitForChild("MusicSystemManager"))
			end

			local musicZonesContainer = backgroundMusic:WaitForChild("BackgroundMusicZones")
			local musicZone = musicZonesContainer:FindFirstChild(syncConfiguration.ZoneName, true)
			if not musicZone then
				scope:log({
					`Could not find music zone named "{syncConfiguration.ZoneName}"`,
					type = "warn",
				})
				return
			end

			local lastBeat = -1
			local shownNextBeat = false
			while task.wait(REFRESH_RATE) do
				local currentZone = musicManager.CurrentZone
				if not currentZone or currentZone.instance ~= musicZone then
					continue
				end

				local currentSound = musicManager.CurrentSong
				if not currentSound or currentSound.zoneID ~= currentZone.id then
					continue
				end

				local position = currentSound.song.TimePosition
				local beat = syncData:BeatFromSecond(position)
				local beatIntegral, fraction = math.modf(beat)
				if lastBeat ~= beatIntegral then
					lastBeat = beatIntegral
					shownNextBeat = false
					toggleBeatBlock((beatIntegral % totalBeats) + 1)
				end

				if not shownNextBeat and fraction >= configuration.IndicatorInterval then
					shownNextBeat = true
					displayNext(((beatIntegral + 1) % totalBeats) + 1)
				end
			end
		else
			--> Default Mode
			local currentBeat = 0
			while true do
				currentBeat = (currentBeat % totalBeats) + 1
				toggleBeatBlock(currentBeat)

				local indicatorTime = if configuration.Indicator then configuration.IndicatorInterval else 0
				task.wait(configuration.Interval - indicatorTime)
				displayNext((currentBeat % totalBeats) + 1)
				if configuration.Indicator then
					task.wait(configuration.IndicatorInterval)
				end
			end
		end
	end)
end

return BeatBlock