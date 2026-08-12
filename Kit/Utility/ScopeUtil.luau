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
    @class ScopeUtil
    @client
    A table of utility functions for working with Scopes that can be used to speed up the process of writing repository scripts for client objects.

]=]
local ScopeUtil = {}

local InternalScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = InternalScopeUtil.Scope

local utilityModule

--[=[
	@within ScopeUtil
	
	Returns the cache with the given `key` from the given `scope`. If not found,
	the `initializer` callback will be ran in order to initialize the cache.
]=]
function ScopeUtil.getCached<T>(scope: Scope, key: string, initializer: (rootScope: any, utility: any) -> T): T
	if not utilityModule then
		-- another cyclic dependency ahhhhhhhhhhhhhh
		utilityModule = require(script.Parent) :: any
	end

	local inCache = scope.shared[key]
	if inCache then
		return inCache :: T
	end

	local returned = initializer(scope.rootScope, utilityModule)
	scope.shared[key] = returned
	return returned
end

return table.freeze(ScopeUtil)
