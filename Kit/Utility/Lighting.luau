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

--[=[
    @class Lighting
    @client
    A table of utility functions for working with Lighting that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Lighting = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local LightingManager = require(Managers.LightingManager)
local LightingManager_Types = require(Managers.LightingManager.TypeDefs)

local ScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = ScopeUtil.Scope

local PREFIX = "TowerDefault"

--[=[
	@within Lighting
	
	Changes the active lighting based on the given `config`.
	See [LightingManager](/api/LightingManager#ChangeLighting) for more info.
]=]
function Lighting.changeLighting(config: LightingManager_Types.LightingConfiguration, scope: Scope?)
	config = table.clone(config)
	if
		(typeof(config.SetDefault) == "string" and config.SetDefault:sub(1, PREFIX:len()) == PREFIX)
		or (typeof(config.UseDefault) == "string" and config.UseDefault:sub(1, PREFIX:len()) == PREFIX)
	then
		ScopeUtil.assertScope(scope, "Lighting.changeLighting()")
		if scope then
			if config.SetDefault then
				config.SetDefault = config.SetDefault:gsub(PREFIX, scope.tower)
			end
			if config.UseDefault then
				config.UseDefault = config.UseDefault:gsub(PREFIX, scope.tower)
			end
		end
	end

	LightingManager:ChangeLighting(config)
end

--[=[
	@within Lighting
	
	Resets all lighting properties back to their default state.
]=]
function Lighting.resetLighting()
	LightingManager:ResetLighting()
end

return table.freeze(Lighting)
