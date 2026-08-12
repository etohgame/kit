--!strict
--!optimize 2
--@version musiczoneeditor-6.1.2
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.TypeDefs)

local DEFAULTS_SET_KEY = "_DEFAULTS_SET"
local DEFAULTS_TEMPLATE = "_DEFAULT_"
local DEFAULTS_TEMPLATE_LENGTH = string.len(DEFAULTS_TEMPLATE)

local MusicZoneEditor = {
	CanQueue = true,
	RunOnStart = false,
}

local EDITOR_CONFIG_TEMPLATE
function MusicZoneEditor.Init(utility: _T.Utility)
	local Config = utility.Config
	EDITOR_CONFIG_TEMPLATE = {
		ZoneName = "",
		OneTimeUse = false,
		Cooldown = 1,
	}
end

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local musicManager
function MusicZoneEditor.Run(scope: _T.Scope, utility: _T.Utility)
	if not musicManager then
		musicManager = require(ReplicatedStorage:WaitForChild("Background Music"):WaitForChild("MusicSystemManager"))
	end

	--> Setup
	local musicZoneEditorConfig = scope.instance
	if not musicZoneEditorConfig then
		return
	end

	local musicZoneEditor = musicZoneEditorConfig.Parent
	if not musicZoneEditor or not musicZoneEditor:IsA("BasePart") then
		return
	end

	--> Get Editor Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, musicZoneEditorConfig, EDITOR_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, musicZoneEditorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, musicZoneEditorConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	scope:attach(musicZoneEditor)

	--> Get music zone data, configuration module, and check for problems
	local musicZonesContainer = ReplicatedStorage:WaitForChild("Background Music"):WaitForChild("BackgroundMusicZones")
	local musicZone = musicZonesContainer:FindFirstChild(configuration.ZoneName, true)

	if not musicZone or not musicZone:IsA("Model") then
		scope:log({
			`MusicZoneEditor was unable to find a music zone named "{configuration.ZoneName}" and cannot function.`,
			`Path: {musicZoneEditor:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local musicZonePriorityIsAttribute = false
	local musicZonePriorityValue = musicZone:FindFirstChild("Priority")
	if not musicZonePriorityValue or not musicZonePriorityValue:IsA("IntValue") then
		musicZonePriorityIsAttribute = true
	end

	local musicZoneMusicFolder = musicZone:FindFirstChild("Music")
	if not musicZoneMusicFolder then
		scope:log({
			`Music zone {musicZone.Name} does not have a Music folder.`,
			`Path: {musicZone:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local musicZoneSoundObjects = {}
	local musicZoneSoundEffectObjects = {}
	for _, object in musicZoneMusicFolder:GetDescendants() do
		if object:IsA("Sound") then
			table.insert(musicZoneSoundObjects, object)
		elseif object:IsA("SoundEffect") then
			musicZoneSoundEffectObjects[object.Name] = object
		end
	end

	if #musicZoneSoundObjects <= 0 then
		scope:log({
			`Music zone {musicZone.Name} has no songs inside of it.`,
			`Path: {musicZone:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local zoneConfigPointer = utility.Instance.getPointer(musicZoneEditorConfig:FindFirstChild("ZoneConfiguration"))
	if not zoneConfigPointer or not zoneConfigPointer:IsA("ModuleScript") then
		scope:log({
			`MusicZoneEditor is missing its "ZoneConfiguraton" module and cannot function.`,
			`Path: {musicZoneEditorConfig:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local zoneConfigData = require(zoneConfigPointer) :: _TDefs.ZoneConfiguration
	local zoneConfigDataType = typeof(zoneConfigData)
	if zoneConfigDataType ~= "table" then
		scope:log({
			`MusicZoneEditor's ZoneConfiguration is formatted incorrectly (expected a table, but received a {zoneConfigDataType})`,
			`Path: {zoneConfigPointer:GetFullName()}`,
			type = "warn",
		})
		return
	end

	--> Functions
	local function getDefaultProperties(object: Instance)
		local properties = {}
		local attributes = object:GetAttributes()

		for attributeName, attributeValue in attributes do
			if attributeName:sub(1, DEFAULTS_TEMPLATE_LENGTH) == DEFAULTS_TEMPLATE then
				local propertyName = attributeName:sub(DEFAULTS_TEMPLATE_LENGTH + 1)
				properties[propertyName] = attributeValue
			end
		end

		return properties
	end

	local function tweenProperties(object: Instance, properties: _TDefs.PropertyTable)
		if properties == "Default" then
			local defaultProperties = getDefaultProperties(object)
			utility.Functions.tween(object, tweenConfiguration, defaultProperties)
			return
		end

		-- set defaults
		if not object:HasTag(DEFAULTS_SET_KEY) then
			object:AddTag(DEFAULTS_SET_KEY)

			for property, _ in properties do
				if object:IsA("Sound") and property == "Volume" then
					object:SetAttribute(`{DEFAULTS_TEMPLATE}{property}`, object:GetAttribute("OriginalVolume"))
				else
					local value = utility.Property.getPropertySafe(object, property)
					object:SetAttribute(`{DEFAULTS_TEMPLATE}{property}`, value)
				end
			end
		end

		-- volume fix
		if properties.Volume then
			object:SetAttribute("OriginalVolume", properties.Volume)
		end

		-- tween properties
		utility.Functions.tween(object, tweenConfiguration, properties)
	end

	local function resetProperties(object: Instance)
		local attributes = object:GetAttributes()

		for attributeName, attributeValue in attributes do
			if attributeName:sub(1, DEFAULTS_TEMPLATE_LENGTH) == DEFAULTS_TEMPLATE then
				local propertyName = attributeName:sub(DEFAULTS_TEMPLATE_LENGTH + 1)
				utility.Property.setPropertySafe(object, propertyName, attributeValue)

				-- volume fix
				if propertyName == "Volume" then
					object:SetAttribute("OriginalVolume", attributeValue)
				end
			end
		end
	end

	local cooldownActive = false
	local oneTimeUseActivated = false
	local function editMusicZone()
		if musicZoneEditor:GetAttribute("Activated") == false then
			return
		end

		-- handle cooldown
		if configuration.Cooldown > 0 then
			if cooldownActive then
				return
			end
			cooldownActive = true
			task.delay(configuration.Cooldown, function()
				cooldownActive = false
			end)
		end

		-- handle one time use
		if configuration.OneTimeUse then
			if oneTimeUseActivated then
				return
			end
			oneTimeUseActivated = true
		end

		local currentSong = musicManager.CurrentSong

		-- set priority
		local zoneDefaultsSet = musicZone:HasTag(DEFAULTS_SET_KEY)
		if zoneConfigData.ZonePriority then
			if musicZonePriorityIsAttribute then
				if not zoneDefaultsSet then
					musicZone:AddTag(DEFAULTS_SET_KEY)
					musicZone:SetAttribute(`{DEFAULTS_TEMPLATE}Priority`, musicZone:GetAttribute("Priority") or 1)
				end
				musicZone:SetAttribute("Priority", zoneConfigData.ZonePriority)
			else
				if not musicZonePriorityValue:HasTag(DEFAULTS_SET_KEY) then
					musicZonePriorityValue:AddTag(DEFAULTS_SET_KEY)
					musicZonePriorityValue:SetAttribute(DEFAULTS_TEMPLATE, musicZonePriorityValue.Value)
				end
				musicZonePriorityValue.Value = zoneConfigData.ZonePriority
			end
		end

		if zoneConfigData.ZoneDisabled ~= nil then
			if not zoneDefaultsSet then
				musicZone:AddTag(DEFAULTS_SET_KEY)
				musicZone:SetAttribute(`{DEFAULTS_TEMPLATE}Disabled`, musicZone:GetAttribute("Disabled") or false)
			end
			musicZone:SetAttribute("Disabled", zoneConfigData.ZoneDisabled)
		end

		-- do extra stuff (this is first due to properties changing)
		if zoneConfigData.ExtraConfiguration then
			local keepTimePosition = zoneConfigData.ExtraConfiguration.KeepTimePosition
			if keepTimePosition and keepTimePosition.Enabled and currentSong then
				for _, sound in musicZoneSoundObjects do
					sound.TimePosition = currentSong.song.TimePosition + keepTimePosition.Offset
				end
			end
		end

		-- set sound properties
		if zoneConfigData.SoundConfiguration then
			for _, sound in musicZoneSoundObjects do
				tweenProperties(sound, zoneConfigData.SoundConfiguration)
			end
		end

		-- set effect properties
		if zoneConfigData.EffectConfiguration then
			for effectName, effect in musicZoneSoundEffectObjects do
				local effectConfig = zoneConfigData.EffectConfiguration[effectName]
				if effectConfig then
					-- cast is used due to roblox not recognising the type correctly
					-- when functionality for Default is added
					tweenProperties(effect, effectConfig :: _TDefs.PropertyTable)
				end
			end
		end
	end

	--> Functionality

	-- reset properties previously changed
	for _, sound in musicZoneSoundObjects do
		resetProperties(sound)
	end
	for _, soundEffect in musicZoneSoundEffectObjects do
		resetProperties(soundEffect)
	end
	if musicZone:HasTag(DEFAULTS_SET_KEY) then
		musicZone:SetAttribute(`Disabled`, musicZone:GetAttribute(`{DEFAULTS_TEMPLATE}Disabled`))
		local priorityAttribute = musicZone:GetAttribute(`{DEFAULTS_TEMPLATE}Priority`)
		if priorityAttribute ~= nil then
			musicZone:SetAttribute("Priority", priorityAttribute)
		end
	end
	if musicZonePriorityValue and musicZonePriorityValue:HasTag(DEFAULTS_SET_KEY) then
		musicZonePriorityValue.Value = musicZonePriorityValue:GetAttribute(DEFAULTS_TEMPLATE)
	end
	
	-- touch functionality
	scope:add(musicZoneEditor.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(musicZoneEditor, toucher, touchConfiguration) then
			return
		end

		editMusicZone()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(musicZoneEditor, editMusicZone))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[musicZoneEditor] = editMusicZone
	scope:add(function()
		cache[musicZoneEditor] = nil
		cache = nil :: any
	end)
end

return MusicZoneEditor
