--!strict
--!optimize 2
-- By @synnwave (09/12/24 DD/MM/YY)

--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

--[=[
    @class LightingManager
    @client
    
    Manager module responsible for the functionality of Lighting Changers
    and other things generally related to lighting.
]=]

--[[
---------------------------------------------------------------------------
Services, modules and other objects
---------------------------------------------------------------------------
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

--[[
---------------------------------------------------------------------------
Constants
---------------------------------------------------------------------------
]]

local CONFIGURABLE_PROPERTIES = {
	ColorCorrectionEffect = { "Brightness", "Contrast", "Saturation", "TintColor" },
	BlurEffect = { "Size" },
	Lighting = {
		"Ambient",
		"Brightness",
		"ClockTime",
		"ColorShift_Bottom",
		"ColorShift_Top",
		"EnvironmentDiffuseScale",
		"EnvironmentSpecularScale",
		"ExposureCompensation",
		"FogColor",
		"FogEnd",
		"FogStart",
		"GeographicLatitude",
		"GlobalShadows",
		"OutdoorAmbient",
		"ShadowSoftness",
		"TimeOfDay",
	},
	BloomEffect = { "Intensity", "Size", "Threshold" },
	DepthOfFieldEffect = { "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity" },
	SunRaysEffect = { "Intensity", "Spread"},
	Atmosphere = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" },
	Sky = {
		"MoonAngularSize",
		"MoonTextureId",
		"SkyboxBk",
		"SkyboxDn",
		"SkyboxFt",
		"SkyboxLf",
		"SkyboxRt",
		"SkyboxUp",
		"StarCount",
		"SunAngularSize",
		"SunTextureId",
		"SkyboxOrientation", -- eyes 👀
	},
} :: { [string]: { string } }

--[[
---------------------------------------------------------------------------
Lighting tables
---------------------------------------------------------------------------
]]

-- Default properties are set here since using Instance.new uses a different set
-- of default properties
local defaultProperties = {
	BloomEffect = { Intensity = 1, Size = 24, Threshold = 2 },
	BlurEffect = { Size = 0 },
	DepthOfFieldEffect = { FarIntensity = 0, FocusDistance = 0, InFocusRadius = 0, NearIntensity = 0 },
	SunRaysEffect = { Intensity = 0, Spread = 0 },
	Atmosphere = { Density = 0, Offset = 0 },
}
local lightingTemplates = {
	PlaceDefault = defaultProperties,
}
local lightingInstances = {}

--[[
---------------------------------------------------------------------------
Main table
---------------------------------------------------------------------------
]]

local LightingManager = {
	__initialized = false,
	Templates = lightingTemplates,
} :: _TDefs.LightingManager

--[[
---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------
]]

--[=[
	@within LightingManager
	
	Changes the active lighting based on the given `config`.
	You can create a lighting preset by using `SetDefault` as a `string` parameter in a
	lighting changer's config module. These can then be reused by using `UseDefault`
	as a `string` parameter with the same value.
]=]
function LightingManager:ChangeLighting(config: _TDefs.LightingConfiguration)
	if CONFIGURABLE_PROPERTIES[config.Type] == nil then
		return
	end

	if not config.TweenInfo then
		config.TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	end

	local lightingInstance = if config.Type == "Lighting" then Lighting else lightingInstances[config.Type]
	local propertyTable = {}
	local thisConfig = if typeof(config.UseDefault) == "string"
		then (
			lightingTemplates[config.UseDefault] and lightingTemplates[config.UseDefault][config.Type]
			or lightingTemplates.PlaceDefault[config.Type]
		)
		elseif config.Configuration == "Default" then lightingTemplates.PlaceDefault[config.Type]
		else config.Configuration

	local saveTo = nil
	if typeof(config.SetDefault) == "string" then
		saveTo = lightingTemplates[config.SetDefault]
		if not saveTo then
			saveTo = {}
			lightingTemplates[config.SetDefault] = saveTo
		end
	end
	if saveTo and saveTo[config.Type] == nil then
		saveTo[config.Type] = {}
	end

	for property, value in thisConfig :: any do
		if saveTo then
			saveTo[config.Type][property] = value
		end

		if property == "Enabled" and config.Type == "Atmosphere" then
			-- For atmospheres we have to parent elsewhere because there is no
			-- .Enabled property
			lightingInstance.Parent = if value then Lighting else script
			continue
		end

		if typeof(value) == "string" or typeof(value) == "boolean" then
			lightingInstance[property] = value
		else
			propertyTable[property] = value
		end
	end

	TweenService:Create(lightingInstance, config.TweenInfo, propertyTable):Play()
end

--[=[
	@within LightingManager
	
	Resets all lighting properties back to their default state.
]=]
function LightingManager:ResetLighting()
	for effectType in CONFIGURABLE_PROPERTIES do
		LightingManager:ChangeLighting({
			Type = effectType,
			Configuration = "Default",
		})
	end
end

--[=[
	@within LightingManager
	
	Removes the registered `preset` from the lighting template list.
	Used when the client object folder unloads.
]=]
function LightingManager:DeregisterPreset(preset: string)
	if preset:lower() == "placedefault" then
		return
	end

	for key in lightingTemplates do
		if key:lower():sub(1, preset:len()) == preset:lower() then
			lightingTemplates[key] = nil
		end
	end
end

function LightingManager:Init()
	if self.__initialized then
		return LightingManager
	end
	self.__initialized = true

	--> Setup lighting defaults
	for _, lightingEffect in Lighting:GetChildren() do
		if lightingEffect:IsA("BloomEffect") and lightingEffect.Enabled then -- Thanks
			defaultProperties.BloomEffect = {
				Intensity = lightingEffect.Intensity,
				Size = lightingEffect.Size,
				Threshold = lightingEffect.Threshold,
			}

			lightingEffect:Destroy()
			break
		end

		if lightingEffect:IsA("BlurEffect") and lightingEffect.Enabled then
			defaultProperties.BlurEffect = { Size = lightingEffect.Size }
			lightingEffect:Destroy()
			break
		end

		if lightingEffect:IsA("DepthOfFieldEffect") and lightingEffect.Enabled then
			defaultProperties.DepthOfFieldEffect = {
				FarIntensity = lightingEffect.FarIntensity,
				FocusDistance = lightingEffect.FocusDistance,
				InFocusRadius = lightingEffect.InFocusRadius,
				NearIntensity = lightingEffect.NearIntensity,
			}

			lightingEffect:Destroy()
			break
		end
		
		if lightingEffect:IsA("SunRaysEffect") and lightingEffect.Enabled then
			defaultProperties.SunRaysEffect = {
				Intensity = lightingEffect.Intensity,
				Spread = lightingEffect.Spread,
			}
		end
	end

	for effect, properties in CONFIGURABLE_PROPERTIES do
		local defaultPropertyTable = {}

		if effect == "Lighting" then
			for _, property in properties do
				defaultPropertyTable[property] = Lighting[property]
			end
		else
			if Lighting:FindFirstChild(`LC{effect}`) == nil then
				local effectDefaults = defaultProperties[effect]
				local effectInstance: Instance = Instance.new(effect)
				if effectInstance:IsA("BlurEffect") then
					effectInstance.Size = effectDefaults.Size or 0
				elseif effectInstance:IsA("DepthOfFieldEffect") then
					effectInstance.FarIntensity = effectDefaults.FarIntensity or 0
					effectInstance.NearIntensity = effectDefaults.NearIntensity or 0
					effectInstance.FocusDistance = effectDefaults.FocusDistance or 0
					effectInstance.InFocusRadius = effectDefaults.InFocusRadius or 0
				elseif effectInstance:IsA("BloomEffect") then
					effectInstance.Intensity = effectDefaults.Intensity or 1
					effectInstance.Size = effectDefaults.Size or 24
					effectInstance.Threshold = effectDefaults.Threshold or 2
				elseif effectInstance:IsA("SunRaysEffect") then
					effectInstance.Intensity = effectDefaults.Intensity or 0
					effectInstance.Spread = effectDefaults.Spread or 0
				elseif effectInstance:IsA("Atmosphere") then
					effectInstance.Density = effectDefaults.Density or 0
					effectInstance.Offset = effectDefaults.Offset or 0
				end

				for i, property in properties do
					defaultPropertyTable[property] = (effectInstance :: any)[property]
				end

				effectInstance.Name = `LC{effect}`
				effectInstance.Parent = Lighting
				lightingInstances[effect] = effectInstance
			end
		end

		defaultProperties[effect] = defaultPropertyTable
	end

	return LightingManager
end

return LightingManager
