--!strict
--!optimize 2
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

--[=[
    @class ClientObjectManager
    @client
    
    Manager module responsible for loading client objects.
]=]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Framework = ReplicatedStorage.Framework
local _TDefs = require(script.TypeDefs)

local Kit = Framework.Kit
local ScopeConstructor = require(Kit.Managers.ScopeConstructor)
local ScopeTypes = require(Kit.Managers.ScopeConstructor.TypeDefs)
local Utility = require(Kit.Utility)
local Log = require(Framework.Log)
local LightingManager = require(Kit.Managers.LightingManager)

local ClientObjectManager = {
	__initialized = false,
	VERSION_NUMBER = "6.1.3", --@kit-version
} :: _TDefs.ClientObjectsController

type Repo = { [string]: any }
type ActiveScripts = { [string]: { [Instance]: boolean } }

local requireCache = {}
local function traverseFolders(folder: Instance, repository: Repo, startingPath: string?)
	local rootPath = startingPath or folder:GetFullName()
	for _, instance in folder:GetChildren() do
		if instance:IsA("ModuleScript") then
			local path = instance:GetFullName():gsub(rootPath, ""):gsub("%.", "/"):sub(2)
			-- the above turns
			-- "ReplicatedStorage.Framework.Kit.Repository.Visual.Emitter"
			-- to: "Visual/Emitter"
			if repository[path] then -- already in repository, skip loading
				continue
			end

			local cached = requireCache[instance]
			if not requireCache[instance] then
				-- requires already cache but i think it'l be a bit more
				-- performant doing this
				local loadSuccess, loadReturns = pcall(require, instance)
				if not loadSuccess then
					Log({
						`Failed to load repository script "{path}"`,
						`Error: "{loadReturns}"`,
						type = "info",
						printType = "warn",
					})
					continue
				end

				cached = loadReturns
				requireCache[instance] = loadReturns
				if typeof(loadReturns) == "table" then
					if loadReturns.Enabled == false then
						continue
					end

					if typeof(loadReturns.Init) == "function" then
						-- This only runs once (--------------> Youonlyliveonce)
						loadReturns.Init(Utility)
						loadReturns.Init = nil
					end
				end
			end

			repository[path] = cached
		elseif instance:IsA("Folder") then
			traverseFolders(instance, repository, rootPath)
		end
	end
end

local function getRepository(overrideRepository: Instance?)
	local repository = {}
	if overrideRepository then
		traverseFolders(overrideRepository, repository)
	end
	traverseFolders(Kit.Repository, repository)
	return repository
end

-- This function must run using scope::spawn or scope::defer
local function runScript(targetScope: ScopeTypes.Scope, scriptPath: string, thisScript: ScopeTypes.RepositoryModule | ScopeTypes.LegacyRepositoryModule, instance: Instance?)
	debug.setmemorycategory(scriptPath)
	local innerScope = targetScope:inherit({
		instance = instance,
		scriptPath = scriptPath,
	})
	if instance then
		targetScope.activeScripts[scriptPath][instance] = true
		innerScope:attach(instance)
	end

	if typeof(thisScript) == "function" then
		thisScript(innerScope, Utility)
	elseif typeof(thisScript) == "table" and typeof(thisScript.Run) == "function" then
		thisScript.Run(innerScope, Utility)
	else
		Log({
			`Repository Script "{scriptPath}" does not have a runner function.`,
			type = "info",
			printType = "warn",
		})
	end

	innerScope:add(function()
		if instance and targetScope.rootScope:isAlive() then
			targetScope.activeScripts[scriptPath][instance] = nil
		end
	end)
end

--[=[
	@within ClientObjectManager
	
	Scans the given folder for Client Objects and loads their scripts.
	Used when certain Client Objects (such as Pushboxes) spawn other COs.
]=]
function ClientObjectManager:ScanFolder(targetScope: ScopeTypes.Scope, path: Instance, targetPath: Instance?)
	local repository = targetScope.repository
	local activeScripts = targetScope.activeScripts

	--> Get objects that shouldnt be loaded in (yet?)
	local objectBlacklist = {}
	for _, instance in CollectionService:GetTagged("SkipObjectLoad") do
		if instance == path or instance:IsDescendantOf(path) then
			objectBlacklist[instance] = true
		end
	end

	--> Get scripts
	for scriptPath, thisScript in repository do
		if typeof(thisScript) == "table" and thisScript.CanQueue == false then
			continue
		end
		
		if not activeScripts[scriptPath] then
			activeScripts[scriptPath] = {}
		end

		for _, instance in CollectionService:GetTagged("CO_" .. scriptPath) do
			if not instance:IsDescendantOf(path) then
				continue
			end       
			if activeScripts[scriptPath] and activeScripts[scriptPath][instance] then
				continue
			end

			local shouldQueue = true
			for blacklistedInstance in objectBlacklist do
				if blacklistedInstance == instance or instance:IsDescendantOf(blacklistedInstance) then
					shouldQueue = false
					break
				end
			end

			if shouldQueue then
				targetScope:defer(runScript, targetScope, scriptPath, thisScript, instance)
			end
		end
	end
	
	if targetPath then
		for _, instance in path:GetChildren() do
			instance.Parent = targetPath
		end
	end
end

--[=[
	@within ClientObjectManager
	
	Loads the client objects found in `from` into the `target`, setting them up and running
	their respective repository scripts.
	
	`towerRepository` determines where the repository scripts for COs will be retrieved from.
	If not set, this will default to `Framework.Kit.Repository`.
]=]
function ClientObjectManager:LoadClientObjects(
	from: Instance,
	target: Instance,
	tower: string,
	towerRepository: Instance?
)
	if not from.Parent then
		-- Temporarily parent container under this script so CollectionService
		-- can detect instances (roblox should add a search parameter...)
		from.Parent = script
	end

	local thisRepository = getRepository(towerRepository)
	local rootScope = ScopeConstructor.new({
		tower = tower,
		clientObjects = target,
		repository = thisRepository,
	})

	local container = rootScope:add(Instance.new("Folder"))
	container.Name = `{tower}TempContainer`
	container.Parent = ReplicatedStorage
	rootScope.shared.TempContainer = container
	
	--> Load RunOnStart repo scripts
	for scriptPath, thisScript in thisRepository do
		if typeof(thisScript) == "table" and thisScript.RunOnStart then
			rootScope:spawn(runScript, rootScope, scriptPath, thisScript)
		end
	end

	--> Scan folder for repo scripts
	ClientObjectManager:ScanFolder(rootScope, from, target)
	from:Destroy()

	--> Deregister any lighting presets & cleanup variables on scope cleanup
	local tower = rootScope.tower
	rootScope:add(function()
		LightingManager:DeregisterPreset(tower)
		table.clear(rootScope.activeScripts)
		table.clear(thisRepository)
		rootScope = nil :: any
	end)

	return rootScope
end

function ClientObjectManager:Init()
	if self.__initialized then
		return ClientObjectManager
	end
	self.__initialized = true

	--> Set Invisible Parts
	for i, tag in { "Invisible", "AltInvisible" } do
		local property = if i == 2 then "LocalTransparencyModifier" else "Transparency"
		for _, instance in CollectionService:GetTagged(tag) do
			if instance:IsA("BasePart") then
				instance[property] = 1
			end
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if instance:IsA("BasePart") then
				instance[property] = 1
			end
		end)
	end

	--> Destroy parts that should only be visible in studio
	for _, instance in CollectionService:GetTagged("OnlyInStudio") do
		instance:Destroy()
	end
	CollectionService:GetInstanceAddedSignal("OnlyInStudio"):Connect(function(instance)
		instance:Destroy()
	end)

	return ClientObjectManager
end

return ClientObjectManager
