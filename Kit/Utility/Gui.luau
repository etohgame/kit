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
	@class Gui
	@client
	A table of utility functions for working with GUIs that can be used to speed up the process of writing repository scripts for client objects.
	
]=]
local Gui = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local GuiManager = require(Managers.GuiManager):Init()
local GuiManager_Types = require(Managers.GuiManager.TypeDefs)
local CharacterManager_Types = require(Managers.CharacterManager.TypeDefs)

Gui.EffectGui = GuiManager.Gui -- DEPRECATED: use `Gui.getEffectGui()` instead

--[=[
	@within Gui
	
	Returns the EffectGui.
]=]
function Gui.getEffectGui(): typeof(GuiManager.Gui)
	return GuiManager.Gui
end

-- Expose EffectGui Manager methods

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#BindKeyCache) for more info.
]=]
function Gui.bindKeyCache(cache: GuiManager_Types.KeyCache)
	return GuiManager:BindKeyCache(cache)
end

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#UnbindKeyCache) for more info.
]=]
function Gui.unbindKeyCache(cache: GuiManager_Types.KeyCache)
	return GuiManager:UnbindKeyCache(cache)
end

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#CreateBoostFrame) for more info.
]=]
function Gui.createBoostFrame(boostData: CharacterManager_Types.BoostData): GuiManager_Types.BoostTimerFrame
	return GuiManager:CreateBoostFrame(boostData)
end

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#UpdateBoostFrame) for more info.
]=]
function Gui.updateBoostFrame(boostData: CharacterManager_Types.BoostData)
	return GuiManager:UpdateBoostFrame(boostData)
end

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#FormatBoostTimer) for more info.
]=]
function Gui.formatBoostTimer(boostData: CharacterManager_Types.BoostData): string
	return GuiManager:FormatBoostTimer(boostData)
end

--[=[
	@within Gui
	
	See [GuiManager](/api/GuiManager#DestroyBoostFrame) for more info.
]=]
function Gui.destroyBoostFrame(boostData: CharacterManager_Types.BoostData)
	return GuiManager:DestroyBoostFrame(boostData)
end

return table.freeze(Gui)
