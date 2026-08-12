--!strict
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

local Utility = {}

local Methods = {}

Utility.Config = require(script.Config)
Utility.ClientObjects = require(script.ClientObjects)
Utility.Character = require(script.Character)
Utility.Property = require(script.Property)
Utility.Table = require(script.Table)
Utility.Functions = require(script.Functions)
Utility.Lighting = require(script.Lighting)
Utility.JumpButton = require(script.JumpButton)
Utility.Gui = require(script.Gui)
Utility.Instance = require(script.Instance)
Utility.Scope = require(script.ScopeUtil)
Utility.SongTime = require(script.SongTime)

export type Utility = typeof(Utility)

return table.freeze(Utility)
