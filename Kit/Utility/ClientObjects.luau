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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
	@class ClientObjects
	@client
	A table of utility functions for working with Client Objects that can be used to speed up the process of writing repository scripts for client objects.
]=]
local ClientObjects = {}

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local Config = require(script.Parent.Config)
local Functions = require(script.Parent.Functions)
local Character = require(script.Parent.Character)
local Table = require(script.Parent.Table)
local localPlayer = Players.LocalPlayer

local ScopeUtil = require(script.Parent.InternalScopeUtil)
type Scope = ScopeUtil.Scope

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance`
	is a ButtonActivatedPlatform.
	
	This will return `true` if it is a `BasePart` and meets
	one of the following requirements:
		
	* Is named `ButtonActivatedPlatform`
	* Has a tag named `ButtonActivated`
]=]
function ClientObjects.isButtonActivatedPlatform(platform: Instance): boolean
	if typeof(platform) ~= "Instance" then
		return false
	end
	return platform:IsA("BasePart")
		and (platform.Name == "ButtonActivatedPlatform" or platform:HasTag("ButtonActivated"))
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a dispensed Balloon.
	
	This will return `true` if it meets one of the following requirements:
		
	* Is named `BalloonModel`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `BalloonModel`
]=]
function ClientObjects.isBalloon(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return parent.Name == "BalloonModel"
		or ((not doNotCheckAncestor) and parent:FindFirstAncestor("BalloonModel") ~= nil)
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a Turret's bullet.
	
	This will return `true` if it meets one of the following requirements:
	
	* Is named `Bullet`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `Bullet`
		
]=]
function ClientObjects.isTurret(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return parent.Name == "Bullet"
		or parent:HasTag("IsBullet")
		or ((not doNotCheckAncestor) and parent:FindFirstAncestor("Bullet") ~= nil)
end

--[=[
	@within ClientObjects
	@tag shorthand

	This function is used to check if the provided `Instance` 
	is part of a Pushbox.
	This will return `true` if it meets one of the following requirements:
	
	* Is named `Pushbox`
	* Has a tag named `IsBox`
	* If `doNotCheckAncestor` is not `true` and the `Instance` has an ancestor
	named `Pushbox`
]=]
function ClientObjects.isPushbox(parent: Instance, doNotCheckAncestor: boolean?): boolean
	if typeof(parent) ~= "Instance" then
		return false
	end
	return (parent.Name == "Pushbox")
		or parent:HasTag("IsBox")
		or ((not doNotCheckAncestor) and parent:FindFirstAncestor("Pushbox") ~= nil)
end

--[=[
    @within ClientObjects
    
    This function checks if the given `toucher` is part of the character's hitbox mode provided.
]=]
function ClientObjects.validatePlayerToucher(toucher: BasePart, mode: Character.HitboxModes?): boolean
	local realMode: string? = mode
	if typeof(mode) ~= "string" or not table.find(Character.HitboxModes, mode) then
		realMode = nil
	end

	local parts = Character.getHitbox(realMode or "WholeBody")
	if not realMode then
		parts = Table.Extend(parts, Character.getHitbox("StaticWholeBody"))
	end
	return table.find(parts, toucher) ~= nil
end

local defaultTouchConfig = Config.GetConfig(nil, nil, Config.TOUCH_CONFIG)

--[=[
	@within ClientObjects
	
	This function checks if two `BasePart`s (`part` and `toucher`) touching
	is considered valid or not, based on the provided `config`.
	
	See [this page](/docs/global-configurations/touch-configurations) for more info.
]=]
function ClientObjects.evaluateToucher(
	part: BasePart,
	toucher: BasePart,
	config: (Instance | typeof(Config.TOUCH_CONFIG))?
): boolean
	if not ((toucher and toucher:IsA("BasePart")) and toucher.Parent) then
		return false
	end
	if not (part and part:IsA("BasePart")) then
		return false
	end

	local checks: typeof(Config.TOUCH_CONFIG)
	if typeof(config) == "Instance" then
		checks = Config.GetConfig(nil, config:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
	else
		checks = config or defaultTouchConfig
	end

	local configuration = if typeof(config) == "Instance" then config else part
	local colorSpecificColor = if typeof(checks.colorSpecificColor) == "Color3"
		then checks.colorSpecificColor
		else Functions.roundColor(part.Color)
	local isColorSpecific = not (checks.colorSpecific and (Functions.roundColor(toucher.Color) ~= colorSpecificColor))

	-- TODO: should i make this check use CollisionGroupsAreCollidable?
	local isCollisionGroup = if checks.collisionGroup then toucher.CollisionGroup == checks.collisionGroup else true

	return (
		if checks.player
			then ClientObjects.validatePlayerToucher(toucher, checks.playerHitboxMode) and isCollisionGroup
			else false
	)
		or (if checks.pushbox then ClientObjects.isPushbox(toucher) and isColorSpecific and isCollisionGroup else false)
		or (if checks.balloon then ClientObjects.isBalloon(toucher) and isColorSpecific and isCollisionGroup else false)
		or (if checks.turret then ClientObjects.isTurret(toucher) and isColorSpecific and isCollisionGroup else false)
end

local FlipManager = require(Managers.FlipManager)

--[=[
	@within ClientObjects
	
	Binds the `callback` function to the `part`, executing the callback when
	the player performs a corner flip on it.
]=]
function ClientObjects.bindToFlip(part: BasePart, callback: (rootPart: BasePart) -> ()): () -> ()
	return FlipManager:BindToFlip(part, callback)
end

--[=[
	@within ClientObjects
	
	Function to format timer labels in a standardized manner, used in Buttons and Morphers.
	Below are special codes that are replaced within the string automatically.
	
	|  Code  | Replaced with: |
	|--------|---------------------------|
	| `{T}` | The time left on the timer, modified with `TimerDecimalPlaces` |
	| `{M}` | The minutes left on the timer |
	| `{S}` | The seconds left on the timer |
	| `{MS}` | The milliseconds left on the timer |
	| `{SM}` | Used for grammatical reasons. When the amount of minutes left is equal to one, this will display the letter "s", otherwise this will display nothing. e.g. "minute{SM}" will either display "minutes" or "minute". |
	| `{SS}` | Used for grammatical reasons. When the amount of seconds left is equal to one, this will display the letter "s", otherwise this will display nothing. e.g. "second{SM}" will either display "seconds" or "second". |
	| `{Pn}` | The player's username |
	| `{pn}` | The username in all lowercase |
	| `{PN}` | The username in all UPPERCASE |
	| `{Dn}` | The player's Display Name |
	| `{dn}` | The Display Name in all lowercase |
	| `{DN}` | The Display Name in all UPPERCASE |
	| `{UID}` | The player's User ID |
]=]
function ClientObjects.formatTimerText(text: string, decimalPlaces: number, timeRemaining: number): string
	decimalPlaces = math.max(0, decimalPlaces // 1)
	local displayTime = if decimalPlaces == 0
		then tostring(math.ceil(timeRemaining)) -- off by 0.5s otherwise
		else string.format(`%.{decimalPlaces}f`, timeRemaining)

	local flooredSeconds = timeRemaining // 1
	local minutes = flooredSeconds // 60
	local seconds = flooredSeconds % 60
	local milliseconds = math.floor(timeRemaining * 100) % 100

	local playerName = localPlayer.Name
	local playerDisplayName = localPlayer.DisplayName

	return text:gsub("{T}", displayTime)
		:gsub("{M}", tostring(minutes))
		:gsub("{SM}", if tostring(minutes) == "1" then "" else "s")
		:gsub("{S}", string.format("%02i", seconds))
		:gsub("{MS}", string.format("%02i", milliseconds))
		:gsub("{SS}", if displayTime == "1" then "" else "s")
		:gsub("{pn}", playerName:lower())
		:gsub("{Pn}", playerName)
		:gsub("{PN}", playerName:upper())
		:gsub("{dn}", playerDisplayName:lower())
		:gsub("{Dn}", playerDisplayName)
		:gsub("{DN}", playerDisplayName:upper())
		:gsub("{UID}", localPlayer.UserId)
end

--[=[
	@within ClientObjects
	
	Returns whether the provided `Instance` is active or not.
]=]
function ClientObjects.isInstanceActive(scope: Scope, instance: Instance, ignoreList: { [string]: boolean }?): boolean
	ScopeUtil.assertScope(scope, "ClientObjects.isInstanceActive()")

	local activeData = scope.shared.activeInstances :: any
	if not activeData then
		return true
	end
	if activeData[instance] then
		for key, active in activeData[instance] do
			if ignoreList and ignoreList[key] then
				continue
			end
			if not active then
				return false
			end
		end
	end

	return true
end

local function getActiveData(scope: Scope): any
	local activeData = scope.shared.activeInstances
	if not activeData then
		activeData = { __bindable = scope:getCommunicator("event", "activeInstancesChanged") }
		scope.shared.activeInstances = activeData
	end

	return activeData
end

--[=[
	@within ClientObjects
	
	Listens to the `Instance`'s activeness, executing the `callback` when
	it's activeness changes.
]=]
function ClientObjects.listenInstanceActive(
	scope: Scope,
	instance: Instance,
	ignoreList: { [string]: boolean }?,
	callback: (active: boolean) -> ()
): () -> ()
	ScopeUtil.assertScope(scope, "ClientObjects.listenInstanceActive()")

	local activeData = getActiveData(scope)
	return scope:add(activeData.__bindable:listen(function(changedInstance)
		if instance == changedInstance then
			callback(ClientObjects.isInstanceActive(scope, instance, ignoreList))
		end
	end))
end

--[=[
	@within ClientObjects
	
	Sets the `Instance`'s activeness based on `active`.
	Instances can have multiple activeness states, dictated by the `key` parameter.
]=]
function ClientObjects.setInstanceActive(scope: Scope, instance: Instance, key: string, active: boolean)
	ScopeUtil.assertScope(scope, "ClientObjects.setInstanceActive()")

	local activeData = getActiveData(scope)
	local thisInstanceData = activeData[instance]
	if not thisInstanceData then
		thisInstanceData = {}
		activeData[instance] = thisInstanceData
	end

	if thisInstanceData[key] ~= active then
		activeData[instance][key] = active
		task.defer(function()
			instance:SetAttribute("Activated", ClientObjects.isInstanceActive(scope, instance))
			activeData.__bindable:fire(instance)
		end)
	end
end

--@kit-version
local VERSION_LIST: {string} = {
	"v6.0.0",
	"v6.0.1",
	"v6.0.2",
	"v6.1.0",
	"v6.1.1",
	"v6.1.2",
	"v6.1.3",
}

--[=[
	@within ClientObjects
	
	This function returns the current version of the Client Object.
	The version only changes between versions when changes are made
	to a repository script.
]=]
function ClientObjects.getCOVersion(config: Instance): string
	for _, tag: string in config:GetTags() do
		if tag:match("^v%d+%.%d+%.%d+$") then
			return tag
		end
	end
	
	return VERSION_LIST[#VERSION_LIST]
end

--[=[
	@within ClientObjects
	
	This function returns whether the `currentVersion` is equal or above the
	`targetVersion`. Versions are defined in-order in the `VERSION_LIST` table.
]=]
function ClientObjects.isVersionOrHigher(currentVersion: string, targetVersion: string): boolean
	local currentNum = table.find(VERSION_LIST, currentVersion)
	local targetNum = table.find(VERSION_LIST, targetVersion)
	
	if not currentNum or not targetNum then
		return false
	end
	
	return currentNum >= targetNum
end

local coManager: any

--[=[
	@within ClientObjects
	
	Scans the given folder and loads any client objects within into the given scope.
	Used for client objects that can spawn other client objects, such as Pushboxes.
]=]
function ClientObjects.scanFolder(targetScope: Scope, path: Instance, targetPath: Instance?)
	ScopeUtil.assertScope(targetScope, "ClientObjects.scanFolder()")
	if not coManager then
		-- cyclic dependency ugh
		coManager = require(Managers.ClientObjectManager) :: any
	end

	coManager:ScanFolder(targetScope, path, targetPath)
end

return table.freeze(ClientObjects)