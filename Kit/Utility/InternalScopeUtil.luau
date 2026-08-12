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
local InternalScopeUtil = {}

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers
local ScopeConstructor = require(Managers.ScopeConstructor)
local ScopeConstructor_TypeDefs = require(Managers.ScopeConstructor.TypeDefs)

export type Scope = ScopeConstructor_TypeDefs.Scope
local isScope = ScopeConstructor.isScope

InternalScopeUtil.isScope = isScope
function InternalScopeUtil.assertScope(scope: any, warning)
	if not isScope then
		error(`Scope expected for {warning}, got {typeof(scope)}`, 4)
	end
end

return table.freeze(InternalScopeUtil)
