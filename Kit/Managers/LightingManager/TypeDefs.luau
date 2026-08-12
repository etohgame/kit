--!strict
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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local APIDump = require(ReplicatedStorage.Framework.ClientTypes.APIDump)

--[=[
	@interface LightingConfiguration
	@within LightingManager
	.Type string
	.Configuration Default | { [string]: any }
	.TweenInfo TweenInfo?
	.UseDefault string?
	.SetDefault string?
]=]
export type LightingConfiguration = {
	Type: string,
	Configuration: "Default" | { [string]: any },
	TweenInfo: TweenInfo?,
	UseDefault: string?,
	SetDefault: string?,
}

export type LightingManager = {
	--> BaseController
	Init: (self: LightingManager) -> LightingManager,
	__initialized: boolean,

	--> LightingManager
	Templates: { [string]: { [string]: any } },
	ChangeLighting: (self: LightingManager, config: LightingConfiguration) -> (),
	ResetLighting: (self: LightingManager) -> (),
	DeregisterPreset: (self: LightingManager, preset: string) -> (),
}

return nil
