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
local StarterGui = game:GetService("StarterGui")
local Kit = ReplicatedStorage.Framework.Kit

local CharacterManager_Types = require(Kit.Managers.CharacterManager.TypeDefs)
local KeyGroup_Types = require(Kit.Repository.Interactables.KeyGroup.TypeDefs)

export type BoostTimerFrame = typeof(script.Parent.BoostFrame) -- allows autocomplete
export type KeyCache = KeyGroup_Types.Cache

export type GuiManager = {
	--> BaseController
	Init: (self: GuiManager) -> GuiManager,
	__initialized: boolean,

	--> GuiManager
	Gui: typeof(StarterGui.EffectGUI),

	KeyDisplayLimit: number,
	BindKeyCache: (self: GuiManager, cache: KeyGroup_Types.Cache) -> (),
	UnbindKeyCache: (self: GuiManager, cache: KeyGroup_Types.Cache) -> (),
	__updateKeyDisplay: (self: GuiManager) -> (),
	__keyCaches: { [string]: KeyGroup_Types.Cache },
	
	DisplayGUI: (self: GuiManager, guiName: string, ...any) -> (),
	PlayerGui: PlayerGui,

	CreateBoostFrame: (self: GuiManager, boostData: CharacterManager_Types.BoostData) -> BoostTimerFrame,
	UpdateBoostFrame: (self: GuiManager, boostData: CharacterManager_Types.BoostData) -> (),
	FormatBoostTimer: (self: GuiManager, boostData: CharacterManager_Types.BoostData) -> string,
	DestroyBoostFrame: (self: GuiManager, boostData: CharacterManager_Types.BoostData) -> (),
}

return nil
