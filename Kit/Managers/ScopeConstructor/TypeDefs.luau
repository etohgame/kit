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
local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log.TypeDefs)

-----------------------------------------
--> Communicator Types

export type COMMUNICATOR_TYPES = "event" | "request"

export type __Communicator_params = {
	type: COMMUNICATOR_TYPES,
	name: string,

	__listener: ((...any) -> ...any)?,
	__hash: { [any]: any },
	__threads: { [thread]: any },
	__scope: any,
	__instance: BindableEvent | BindableFunction,
}

export type __Communicator_metatable = {
	__index: __Communicator_metatable,
	__newindex: nil,
	__tostring: (self: ScopeCommunicator) -> string,
	__metatable: "ScopeCommunicator",

	listen: (self: ScopeCommunicator, callback: (...any) -> ...any) -> () -> (),
	listenOnce: (self: ScopeCommunicator, callback: (...any) -> ...any) -> () -> (),
	listenWait: (self: ScopeCommunicator) -> ...any,
	fire: (self: ScopeCommunicator, ...any) -> ScopeCommunicator,
	request: (self: ScopeCommunicator, ...any) -> ...any,
	destroy: (self: ScopeCommunicator) -> (),
}

export type ScopeCommunicator = typeof(setmetatable({} :: __Communicator_params, {} :: __Communicator_metatable))

-----------------------------------------
--> Scope Types

export type RepositoryModule = { Run: (scope: Scope, repository: any) -> (), [string]: any }
export type LegacyRepositoryModule = (scope: Scope, repository: any) -> ()

export type __Scope_params = {
	instance: Instance?,
	scriptPath: string,

	rootScope: Scope,
	parentScope: Scope?,
	id: string,

	-- global scope items
	tower: string,
	clientObjects: Instance,
	shared: {
		TempContainer: Instance,
		[any]: unknown,
	},
	debug: boolean,
	repository: { [string]: (LegacyRepositoryModule | RepositoryModule)? },

	active: boolean,
	activeScripts: { [string]: { [Instance]: boolean } },

	-- private items
	--__root: nil, -- hidden property
	__items: { __cleaning: boolean, [number]: any },
	__communicators: {
		event: { [string]: ScopeCommunicator? },
		request: { [string]: ScopeCommunicator? },
		hash: { [any]: any },
	},
}

export type __Scope_metatable = {
	__index: __Scope_metatable,
	__newindex: nil,
	__tostring: (self: Scope) -> string,
	__metatable: "Scope",

	inherit: (self: Scope, data: { [string]: any }?) -> Scope,
	add: <T...>(self: Scope, T...) -> T...,
	remove: (self: Scope, item: unknown, doNotCleanup: boolean?) -> Scope,
	cleanup: (self: Scope, defer: boolean?, destroy: boolean?) -> Scope,
	attach: (self: Scope, instance: Instance, removeFromParentScope: boolean?) -> (RBXScriptConnection, Instance),
	isAlive: (self: Scope) -> boolean,

	spawn: <T...>(self: Scope, fn: (T...) -> ...unknown, T...) -> thread,
	defer: <T...>(self: Scope, fn: (T...) -> ...unknown, T...) -> thread,
	delay: <T...>(self: Scope, seconds: number, fn: (T...) -> ...unknown, T...) -> thread,

	getCommunicator: (self: Scope, type: COMMUNICATOR_TYPES, key: string) -> ScopeCommunicator,
	log: (self: Scope, data: Log.logData) -> Scope,
}

export type Scope = typeof(setmetatable({} :: __Scope_params, {} :: __Scope_metatable))

export type __constructorData = {
	tower: string,
	clientObjects: Instance,
	repository: any,
}
export type ScopeConstructor = {
	new: (data: __constructorData) -> Scope,
	isScope: (scope: any) -> boolean,
}

return nil
