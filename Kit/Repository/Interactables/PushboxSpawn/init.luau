--!strict
--!optimize 2
--@version pushboxspawn-6.1.2
--@creator synnwave
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 

PLEASE, **DO NOT** make any script edits to this script.
To make a script edit, please read the following:
https://etohgame.github.io/kit/docs/misc#writingediting-repository-scripts

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)

local SPAWN_CONFIG_TEMPLATE = {
	Cooldown = 0.5,
	DontSpawnFirst = true,
}

local PushboxSpawn = {
	CanQueue = true,
	RunOnStart = false,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function PushboxSpawn.Run(scope: _T.Scope, utility: _T.Utility)
	local spawnConfig = scope.instance
	if not spawnConfig or not spawnConfig.Parent then
		return
	end

	local pushboxSpawner = spawnConfig.Parent
	if not pushboxSpawner or not pushboxSpawner:IsA("Model") then
		return
	end

	local pushboxTemplate = spawnConfig.Parent:FindFirstChild("Pushbox")
	if not pushboxTemplate then
		return
	end
	if not pushboxTemplate:HasTag("SkipObjectLoad") then
		scope:log({
			"Pushbox is missing it's 'SkipObjectLoad' tag.",
			`Path: {pushboxTemplate:GetFullName()}`,
			type = "warn",
		})
		return
	end
	
	local function anchorModel(model: typeof(pushboxTemplate), anchored: boolean)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and not part:HasTag("BoxAnchor") then
				part.Anchored = false
			end
		end
	end
	
	local coUtil = utility.ClientObjects
	local coVersion = coUtil.getCOVersion(spawnConfig)
	
	--> set up box template
	scope:add(pushboxTemplate)
	
	pushboxTemplate.Parent = nil
	pushboxTemplate:RemoveTag("SkipObjectLoad")
	-- ^ this line above is important to reduce IsDescendantOf checks and also
	-- allows nested pushboxes to actually work

	--> Get Configurations
	local spawnSound = spawnConfig:FindFirstChild("SpawnSound")
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, spawnConfig, SPAWN_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, spawnConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

	--> Main Functionality
	local cooldown = false
	local pushboxScope = scope:inherit()
	local function spawnPushbox(activator: BasePart?)
		if cooldown or (activator and activator:GetAttribute("Activated") == false) then
			return
		end
		cooldown = true
		task.delay(configuration.Cooldown, function()
			cooldown = false
		end)

		if spawnSound and spawnSound:IsA("Sound") then
			spawnSound:Play()
		end
		pushboxScope:cleanup()
		local thisBox = pushboxScope:add(pushboxTemplate:Clone())
		thisBox.Parent = spawnConfig.Parent
		if coUtil.isVersionOrHigher(coVersion, "v6.1.2") then
			anchorModel(thisBox, false)
		end
		utility.ClientObjects.scanFolder(pushboxScope, thisBox)
	end

	--> Activation
	scope:attach(pushboxSpawner)

	for _, button in pushboxSpawner:GetChildren() do
		if button.Name == "Button" and button:IsA("BasePart") then
			scope:add(button.Touched:Connect(function(touchingPart: BasePart)
				if not utility.ClientObjects.evaluateToucher(button, touchingPart, touchConfiguration) then
					return
				end

				spawnPushbox()
			end))

			if touchConfiguration.canFlip then
				scope:add(utility.ClientObjects.bindToFlip(button, spawnPushbox))
			end
		end
	end

	if not configuration.DontSpawnFirst then
		task.defer(spawnPushbox)
	end

	--> Sequencer Cache Support
	local spawnerModel = spawnConfig.Parent
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[spawnerModel] = spawnPushbox
	scope:add(function()
		cache[spawnerModel] = nil
		cache = nil :: any
	end)
end

return PushboxSpawn
