--!strict
--!optimize 2
-- By @synnwave (26/01/25 DD/MM/YY)
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)
local Type = require(script.Type)
local ScopeUtil = require(script.Parent.InternalScopeUtil)

local DEFAULT_TOUCH_CONFIGURATION = table.freeze({
	player = true,
	canFlip = Type.boolean,
	pushbox = Type.boolean,
	colorSpecific = Type.boolean,
	colorSpecificColor = Type.Color3,
	balloon = Type.boolean,
	turret = Type.boolean,
	collisionGroup = Type.string,
	playerHitboxMode = Type.string,
})

local DEFAULT_TWEEN_CONFIGURATION = table.freeze({
	Time = 1,
	Style = Type.Enum(Enum.EasingStyle.Linear),
	Direction = Type.Enum(Enum.EasingDirection.Out),
})

--[=[
    @class Config
    @client
    A table of utility functions that can be used to speed up the process of writing repository scripts for client objects.
    
]=]
local Config = {
	Type = Type,
	TOUCH_CONFIG = DEFAULT_TOUCH_CONFIGURATION,
	TWEEN_CONFIG = DEFAULT_TWEEN_CONFIGURATION,
}

local function processValue(value: any, default: any): (any, boolean?)
	if typeof(default) == "table" and default.type then
		if default.type == "any" then
			return value, false
		elseif default.type == "none" then
			return nil, false
		elseif default.type == "some" and default.value then
			for _, otherValue in ipairs(default.value) do
				local processed, valueMatchFailed = processValue(value, otherValue)
				if
					not valueMatchFailed
					and ((typeof(otherValue) == "table" and otherValue.type) or value == otherValue)
				then
					return processed
				end
			end

			local fallback = default.value[1]
			if typeof(fallback) == "table" then
				fallback = if fallback.type == "literal" then fallback.value else nil
			end

			return fallback
		elseif default.type == "literal" then
			local matched = default.value == value
			return (if matched then value else nil), not matched
		elseif (not default.ignoreType) and typeof(value) ~= default.type then
			return nil, true
		end

		local thisValue = value
		if default.processor then
			thisValue = default.processor(value)
		end

		if default.check then
			local check, error = default.check(value)
			if not check then
				Log({ error, type = "warn" })
				if default.checkFailedProcessor then
					thisValue = default.checkFailedProcessor(value)
				end
			else
				thisValue = value
			end
		end

		return thisValue
	elseif typeof(value) ~= typeof(default) then
		return default
	end

	return value
end

local function getValue(config: Instance?, key: string, default: any)
	local value: any = if config then config:GetAttribute(key) else nil
	return processValue(value, default)
end

local function observeChanges(self: any, callback)
	if not self.__instance then
		return self
	end

	local scope = self.__scope
	ScopeUtil.assertScope(scope, "Config:ObserveChanges()")

	if not self.__callbacks then
		self.__callbacks = {}
		for key, default in self.__defaults do
			scope:add(self.__instance:GetAttributeChangedSignal(key):Connect(function()
				self[key] = getValue(self.__instance, key, default)
				for _, callback in self.__callbacks do
					callback(key, self[key])
				end
			end))
		end
	end

	table.insert(self.__callbacks, callback)
	return self
end

type Scope = ScopeUtil.Scope

-- TODO: improve everything down here lol

--[=[
    @within Config
    
    Returns the given `config` instance as a table. If any properties are
    missing from the instance, it will use the value from the `defaults` table.
]=]
local function getConfig<T>(scope: Scope?, config: Instance, defaults: T)
	local self = {
		__instance = config,
		__defaults = defaults :: any,
		__scope = scope,
		ObserveChanges = observeChanges,
	}
	for key, default in defaults :: any do
		self[key] = getValue(config, key, default)
	end

	if scope and ScopeUtil.isScope(scope) then
		scope:add(function()
			self.__defaults = nil
			table.clear(self)
		end)
	end

	return self :: any
end

type Config_methods = {
	ObserveChanges: <S>(self: S, callback: ((key: string, value: any) -> ())?) -> S,
}
Config.GetConfig = (getConfig :: any) :: <T>(self: Scope?, config: Instance?, defaults: T & {}) -> Config_methods & T

return table.freeze(Config)
