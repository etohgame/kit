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
local Scope_TypeDefs = require(ReplicatedStorage.Framework.Kit.Managers.ScopeConstructor.TypeDefs)

export type ClientObjectsController = {
	--> BaseController
	Init: (self: ClientObjectsController) -> ClientObjectsController,
	__initialized: boolean,

	--> ClientObjectsController
	VERSION_NUMBER: string,
	ScanFolder: (
		self: ClientObjectsController,
		targetScope: Scope_TypeDefs.Scope,
		path: Instance,
		targetPath: Instance?
	) -> (),
	LoadClientObjects: (
		self: ClientObjectsController,
		from: Instance,
		target: Instance,
		tower: string,
		towerRepository: Instance?
	) -> Scope_TypeDefs.Scope,
}

return nil
