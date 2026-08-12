--!strict
--!optimize 2
-- By @synnwave (30/11/24 DD/MM/YY)

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
local HttpService = game:GetService("HttpService")

local _TDefs = require(script.TypeDefs)
local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)

local Kit = Framework.Kit
local Managers = Kit.Managers
local CLEANUP_METHODS = { "Destroy", "Disconnect", "cleanup", "destroy", "disconnect" }

local function doNothing() end
local function generateUID()
	return HttpService:GenerateGUID(false):gsub("-", "")
end

-- private key wrapper shorthand; for items that aren't meant to be accessed
local PRIVATE_KEY = "SCOPE-PRIVATE-" .. generateUID()
local function wrap<T>(t: T): { [any]: T }
	return { [PRIVATE_KEY] = t }
end

--------------------------------------------------------------------------------
--> Setup

--[=[
    @class Scope
    @client
    
    Scopes are used for performance optimizations. Any client objects that get loaded
    are placed into a Scope that will automatically clean up everything contained
    within it when it unloads, in order to prevent lingering Instances and connections
    from using unnecessary processing and memory.
]=]
local Scope = {} :: _TDefs.__Scope_metatable
Scope.__metatable = "Scope"
Scope.__index = function(self: _TDefs.Scope, key: string)
	if key:sub(1, 1) == "_" then
		Scope.log(self, { `Attempt to access private scope property '{key}'`, type = "error" })
	end

	local rawData = self[PRIVATE_KEY]
	if not rawData then
		return
	end

	if key == "rootScope" then
		return rawData.__root or self
	end

	local item = rawData[key]
	if item ~= nil then
		return item
	end

	item = Scope[key]
	if item == nil then -- get item from rootScope
		local rootScope = self.rootScope
		if rootScope == self then
			return nil
		end

		local rawRootScopeData = rootScope and rootScope[PRIVATE_KEY]
		if rawRootScopeData then
			item = item or rawRootScopeData[key]
		end
	end

	return item
end :: any
Scope.__newindex = function(self: _TDefs.Scope, key: string)
	self:log({ `Cannot add property '{key}' to scope ({self.id})`, type = "error", traceback = 4 })
end :: any

function Scope:__tostring()
	return `Scope ({self.scriptPath} - {self.id})`
end

--[=[
    @within Scope
    @prop instance Instance?
    
    The scope's instance.
]=]
--[=[
    @within Scope
    @prop scriptPath string?
    
    The scope's script path.
]=]
--[=[
    @within Scope
    @prop rootScope Scope
    
    The scope's root scope.
]=]
--[=[
    @within Scope
    @prop parentScope Scope
    
    The scope's parent scope.
]=]
--[=[
    @within Scope
    @prop id string
    
    The scope's ID.
]=]
--[=[
    @within Scope
    @prop tower string
    
    The tower's name.
]=]
--[=[
    @within Scope
    @prop clientObjects Instance
    
    The tower's client objects container.
]=]
--[=[
    @within Scope
    @prop shared { [string]: any }
    
    A shared table across every single scope inherited by the rootScope
]=]
--[=[
    @within Scope
    @prop repository { [string]: any }
    
    A table of every single repository script that is currently loaded.
]=]
--[=[
    @within Scope
    @prop active boolean
    
    A variable
]=]
--[=[
    @within Scope
    @prop activeScripts { [string]: { [Instance]: boolean } }
    
    All of the current scripts running
]=]

--[=[
    @within Scope
    
    Logs the provided `data` table into the output.
]=]
function Scope:log(data: any)
	data.path = if self.scriptPath and self.scriptPath ~= "" then ("Repository." .. self.scriptPath) else data.path
	Log(data)
	return self
end

local function isAlive(self: _TDefs.Scope)
	local rawData = self[PRIVATE_KEY]
	return rawData.active
end
Scope.isAlive = isAlive

local function assureScopeIsActive(self: _TDefs.Scope, method: string)
	local rawData = self[PRIVATE_KEY]
	if not rawData.active then
		self:log({
			`Current scope has been destroyed (calling method '{method}', {rawData.id})`,
			type = "error",
			traceback = 4,
		})
	end
end

--------------------------------------------------------------------------------
--> Memory Management

--[=[
    @within Scope
    
    Adds the given items into the Scope, automatically cleaning it up when the
    Scope unloads.
    All of the items that are passed in to this function will be returned right back.
    
    :::info
    It is important that you put all of your Instances and Connections in this 
    function to be cleaned up when the player leaves the tower. Any functions 
    passed in will run when it is time to clean up.
    :::
    
    :::caution
    This function will throw an error if used during the scope's cleanup process.
    :::
]=]
function Scope:add<T...>(...: T...): T...
	assureScopeIsActive(self, "add")

	local items = self[PRIVATE_KEY].__items
	if items.__cleaning then
		self:log({
			"Attempted to add an item to a scope during cleanup",
			traceback = 4,
			type = "error",
		})
	end

	for i = 1, select("#", ...) do
		local item = select(i, ...)
		if item ~= nil and not table.find(items, item) then
			table.insert(items, item)
		end
	end

	return ...
end

--[=[
    @within Scope
    
    Creates a new child Scope within the current Scope. Used for client objects
    that have the capability of spawning other client objects, so cloned models
    can be cleaned up without the entire object's scope being removed.
]=]
function Scope:inherit(data: any)
	assureScopeIsActive(self, "inherit")

	local thisData = data or {}
	local rootScope = self.rootScope
	local rawSelf = self[PRIVATE_KEY]
	local rawRootScope = rootScope[PRIVATE_KEY]
	local newData: any = wrap({
		instance = thisData.instance or rawSelf.instance,
		scriptPath = thisData.scriptPath or rawSelf.scriptPath,
		active = true,

		id = "INNER-" .. generateUID(),
		parentScope = self,

		-- items copied from rootscope to save on __index
		shared = rawRootScope.shared,
		__communicators = rawRootScope.__communicators,
		clientObjects = rawRootScope.clientObjects,
		debug = rawRootScope.debug,

		__root = rootScope,
		__items = { __cleaning = false },
	})

	return Scope.add(self, setmetatable(newData, Scope))
end

local cleanupScope, cleanupItem, destroyScope

local function deepClearTable(this)
	for _, next in this do
		if typeof(next) == "table" then
			deepClearTable(next)
			table.clear(next)
		end
	end

	table.clear(this)
end

function destroyScope(self: _TDefs.Scope)
	local rawData = self[PRIVATE_KEY]
	if not rawData or not rawData.active then
		return
	end
	rawData.active = false
	if not rawData.__items.__cleaning then
		cleanupScope(self)
	end

	if rawData.parentScope then
		rawData.parentScope:remove(self, true)
		rawData.parentScope = nil
	end

	if self.rootScope == self then
		-- Clear all shared tables & repository pointers
		deepClearTable(rawData.shared)
		deepClearTable(rawData.__communicators)
		table.clear(rawData.repository)
	end

	rawData.shared = nil
	rawData.repository = nil
	rawData.__communicators = nil
	rawData.clientObjects = nil

	return self
end

function cleanupItem(item: any)
	local cleanupSuccess, cleanupError
	local type = typeof(item)
	if type == "function" then
		task.spawn(item)
	elseif type == "thread" then
        cleanupSuccess, cleanupError = pcall(task.cancel, item)
        if typeof(cleanupError) == "string" then
            cleanupError ..= ` (status: {coroutine.status(item)})`
        end
	elseif type == "Instance" then
		-- this would only error if the instance has already been destroyed so
		-- there's no need to report errors here
		pcall(item.Destroy, item)
	elseif type == "RBXScriptConnection" then
		cleanupSuccess, cleanupError = pcall(item.Disconnect, item)
	elseif type == "table" then
		if getmetatable(item) == "Scope" then
			destroyScope(item)
		else
			cleanupSuccess, cleanupError = pcall(function()
				for _, method in CLEANUP_METHODS do
					if typeof(item[method]) == "function" then
						item[method](item)
						break
					end
				end
			end)
		end
	end

	if cleanupSuccess == false then
		Log({ "Failed to cleanup scope item", cleanupError, type = "warn" })
	end
end

function cleanupScope(self: _TDefs.Scope, ignoreWarning: boolean?)
	local rawData = self[PRIVATE_KEY]
	local items = rawData.__items
	if not ignoreWarning and items.__cleaning then
		return self:log({ "Scope is already cleaning up!!", traceback = 4, type = "warn" })
	end

	items.__cleaning = true

	local cleaned = {}
	for index, item in ipairs(items) do
		if cleaned[item] then
			continue
		end
		cleaned[item] = true
		cleanupItem(item)
	end

	table.clear(cleaned)
	rawData.__items = { __cleaning = false }

	return self
end

--[=[
    @within Scope
    
    Removes the given item from the Scope. If `doNotCleanup` is set, the object
    will not be automatically destroyed along with this.
]=]
function Scope:remove(item: any, doNotCleanup: boolean?)
	local rawSelf = self[PRIVATE_KEY]
	local items = rawSelf.__items
	if items.__cleaning or not rawSelf.active then
		return self
	end

	local index = table.find(items, item)
	if index then
		table.remove(items, index)
		if not doNotCleanup then
			cleanupItem(item)
		end
	end

	return self
end

--[=[
    @within Scope
    
    Cleans up the Scope.
    If `defer` is set, the cleanup will be deferred rather than occuring immediately.
    If `destroy` is set, the Scope will be fully destroyed rather than only cleaning up.
]=]
function Scope:cleanup(defer: boolean?, destroy: boolean?)
	if self == self.rootScope then
		self:log({
			`WARNING - Cleaning up RootScope`,
			traceback = 4,
			type = "warn",
		})
	end

	local method: any = if destroy then destroyScope else cleanupScope
	if defer then
		task.defer(method, self)
	else
		method(self)
	end

	return self
end

--[=[
    @within Scope
    
    Attaches the Scope to the given `instance`, cleaning up the Scope if
    the instance gets destroyed.
]=]
function Scope:attach(instance: Instance, removeFromParentScope: boolean?)
	assureScopeIsActive(self, "attach")
	if self == self.rootScope then
		self:log({
			`WARNING - ATTEMPTING TO ATTACH INSTANCE TO ROOTSCOPE. DANGEROUS!!`,
			traceback = 4,
			type = "warn",
		})
	end

	if removeFromParentScope then
		Scope.add(self, function()
			destroyScope(self)
		end)
	end

	return Scope.add(
		self,
		instance.Destroying:Connect(function()
			cleanupScope(self, true)
		end),
		instance
	)
end

--------------------------------------------------------------------------------
--> Scope Task Library Wrappers

local frameworkDirectory = Framework:GetFullName()

--[=[
    @within Scope
    
    Runs `task.spawn` with the given function and adds it to the Scope, cancelling
    it if the Scope unloads while the task is running.
]=]
function Scope:spawn<T...>(fn: (T...) -> ...unknown, ...: T...)
	local thread
	thread = Scope.add(
		self,
		task.spawn(function(...)
			fn(...)
			Scope.remove(self, thread, true)
		end, ...)
	)

	return thread
end

--[=[
    @within Scope
    
    Runs `task.defer` with the given function and adds it to the Scope, cancelling
    it if the Scope unloads while the task is running.
]=]
function Scope:defer<T...>(fn: (T...) -> ...unknown, ...: T...)
	local thread
	thread = Scope.add(
		self,
		task.defer(function(...)
			fn(...)
			Scope.remove(self, thread, true)
		end, ...)
	)

	return thread
end

--[=[
    @within Scope
    
    Runs `task.delay` with the given delay/function and adds it to the Scope, cancelling
    it if the Scope unloads while the task is running.
]=]
function Scope:delay<T...>(seconds: number, fn: (T...) -> ...unknown, ...: T...)
	local thread
	thread = Scope.add(
		self,
		task.delay(seconds, function(...)
			fn(...)
			Scope.remove(self, thread, true)
		end, ...)
	)

	return thread
end

--------------------------------------------------------------------------------
--> Scope Communication

---------------------------------------
--> Setup

--[=[
    @class ScopeCommunicator
    @client
    
    Scope Communicators allow Client Objects to easily communicate with eachother.
    
    Instead of using plain BindableEvents/BindableFunctions to communicate between Client Objects,
    use these.
]=]
local Communicator = {} :: _TDefs.__Communicator_metatable
Communicator.__index = Communicator
Communicator.__newindex = function(self: _TDefs.ScopeCommunicator, key: string, value)
	if key == "__listener" then
		rawset(self :: any, key, value)
		return
	end

	self.__scope:log({
		`Cannot add property '{key}' to communicator`,
		traceback = 4,
		type = "error",
	})
end :: any

function Communicator:__tostring()
	return `Communicator ({self.type} - {self.name})`
end

-----------------------------------------
--> Methods

--[=[
    @within ScopeCommunicator
    @param callback () -> ()
    
    Listens for events to the Communicator, executing the `callback` function
    when the Communicator is fired.
]=]
function Communicator:listen(callback)
	if self.type == "event" and self.__instance:IsA("BindableEvent") then
		local connection = self.__instance.Event:Connect(function(id: string)
			callback(table.unpack(self.__hash[id]))
		end)
		Scope.add(self.__scope, connection)
		return function()
			connection:Disconnect()
		end
	elseif self.type == "request" and self.__instance:IsA("BindableFunction") then
		if self.__listener and self.__scope.debug then
			self.__scope:log({
				`Replacing callback for request communicator '{self.name}'`,
				type = "info",
			})
		end

		local function callbackWrapper(id: string)
			-- reuse id to send in new data returned by the callback
			-- wow
			self.__hash[id] = table.pack(callback(table.unpack(self.__hash[id])))
			return id
		end
		self.__listener = callbackWrapper
		self.__instance.OnInvoke = callbackWrapper

		local function disconnect()
			if self.__listener == callbackWrapper then
				self.__instance.OnInvoke = nil :: any
				callbackWrapper = nil :: any
				self.__listener = nil
			end
		end
		return Scope.add(self.__scope, disconnect)
	end

	return doNothing
end

--[=[
    @within ScopeCommunicator
    @param callback () -> ()
    
    Wrapper for the `listen` function that automatically disconnects after one event.
]=]
function Communicator:listenOnce(callback)
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log({
			`Cannot use method 'listenOnce' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		})
		return doNothing
	end

	local disconnect
	disconnect = self:listen(function(...)
		callback(...)
		disconnect()
	end)

	return disconnect
end

--[=[
    @within ScopeCommunicator
    
    Wrapper for the `listenOnce` function that will yield until an event is fired.
]=]
function Communicator:listenWait()
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log({
			`Cannot use method 'listenWait' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		})
		return nil
	end

	local thread = coroutine.running()
	self.__threads[thread] = true
	self:listenOnce(function(...)
		self.__threads[thread] = nil
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

--[=[
    @within ScopeCommunicator
    
    Fires the Communicator with the arguments provided.
]=]
function Communicator:fire(...: any)
	if not self.__instance:IsA("BindableEvent") then
		self.__scope:log({
			`Cannot use method 'fire' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		})
		return self
	end
	if not self.__hash then
		return self
	end

	local id = generateUID()
	self.__hash[id] = table.pack(...)
	self.__instance:Fire(id)

	return self
end

--[=[
    @within ScopeCommunicator
    
    Requests a Communicator based on the provided arguments.
]=]
function Communicator:request(...: any)
	if not self.__instance:IsA("BindableFunction") then
		self.__scope:log({
			`Cannot use method 'request' for communicator type '{self.type}'`,
			traceback = 4,
			type = "error",
		})
		return self
	end

	local id = generateUID()
	self.__hash[id] = table.pack(...)
	self.__instance:Invoke(id)
	local data = self.__hash[id]
	self.__hash[id] = nil
	return table.unpack(data)
end

--[=[
    @within ScopeCommunicator
    
    Destroys the Communicator, disabling its use.
]=]
function Communicator.destroy(self: any)
	if getmetatable(self) ~= Communicator then
		return
	end

	self.__listener, self.__hash = nil
	for thread in self.__threads do
		if coroutine.status(thread) ~= "suspended" then
			continue
		end
		pcall(task.cancel, thread)
	end
	self.__threads = nil

	local rootScope = self.__scope.rootScope
	Scope.remove(rootScope, self.__instance)
	rootScope[PRIVATE_KEY].__communicators[self.type][self.name] = nil
	self.name, self.type, self.__scope = nil

	setmetatable(self, nil)
end

---------------------------------------
--> Creation

--[=[
    @within ScopeCommunicator
    
    Creates a Communicator with the given `type` and `key`.
    
    Current valid `type`s are "event" and "request"
    - "event" types are BindableEvents
    - "request" types are BindableFunctions
]=]
function Scope:getCommunicator(type: _TDefs.COMMUNICATOR_TYPES, key: string)
	assureScopeIsActive(self, "getCommunicator")
	local rootScope = self.rootScope
	local rawRootScope = rootScope[PRIVATE_KEY]
	local communicators = rawRootScope.__communicators

	local existingCommunicator = communicators[type][key]
	if existingCommunicator then
		return existingCommunicator
	end

	local communicatorProps = {
		type = type,
		name = key,

		__hash = communicators.hash,
		__threads = {},
		__scope = self,
	}
	if type == "event" then
		communicatorProps.__instance = Instance.new("BindableEvent") :: any
		communicatorProps.__instance.Event:Connect(function(id: string)
			-- bindable events run in reverse order; this will always run last
			communicatorProps.__hash[id] = nil
		end)
	elseif type == "request" then
		communicatorProps.__instance = Instance.new("BindableFunction")
	end

	communicatorProps.__instance.Parent = script
	communicatorProps.__instance.Name = self.id

	local newCommunicator =
		Scope.add(rootScope, setmetatable(communicatorProps, Communicator), communicatorProps.__instance)
	communicators[type][key] = newCommunicator
	return newCommunicator :: _TDefs.ScopeCommunicator
end

--------------------------------------------------------------------------------

return table.freeze({
	new = function(data: _TDefs.__constructorData): _TDefs.Scope
		local scopeData: any = wrap({
			instance = nil,
			scriptPath = "",

			-- global scope items
			clientObjects = data.clientObjects,
			rootScope = nil,
			shared = {},
			debug = true,
			id = "ROOT-" .. generateUID(),
			tower = data.tower,
			active = true,
			activeScripts = {},
			repository = data.repository,

			-- private items
			__items = { __cleaning = false },
			__communicators = {
				event = {},
				request = {},
				hash = {},
			},
		})

		return setmetatable(scopeData, Scope)
	end,

	isScope = function(scope: any): boolean
		return getmetatable(scope) == Scope.__metatable
	end,
})
