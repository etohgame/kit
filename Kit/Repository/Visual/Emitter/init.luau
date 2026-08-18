--!strict
--!optimize 2
--@version emitter-6.1.3
--@creator Camille, synnwave
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

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local SequencerSupport = require(script.SequencerSupport)

local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local Emitter = {
	CanQueue = true,
	RunOnStart = false,
}

local EMITTER_CONFIG_TEMPLATE = {
	GlobalSound = true,
	Uses = 0, -- refreshes when changed
	Cooldown = 1,
}
local EMMISSION_CONFIG_TEMPLATE
function Emitter.Init(utility: _T.Utility)
	local Config = utility.Config
	
	EMMISSION_CONFIG_TEMPLATE = {
		EmitCount = Config.Type.Some(Config.Type.number, Config.Type.NumberRange, Config.Type.none),
		EmitDelay = 0,
		PitchRange = NumberRange.new(1),
	}
end

function Emitter.Run(scope: _T.Scope, utility: _T.Utility)
	--> Setup
	local emitterConfig = scope.instance
	if not emitterConfig then
		return
	end

	local emitter = emitterConfig.Parent
	if not emitter or not emitter:IsA("BasePart") then
		return
	end

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, emitterConfig, EMITTER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, emitterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(emitter)

	--> Variables
	local cooldownActive = false
	local infiniteUses = configuration.Uses <= 0 -- if set to 0 at first, can be used infinite times

	--> Functions
	local function checkUses()
		if infiniteUses then
			return true
		end
		if configuration.Uses <= 0 then
			return false
		end

		configuration.Uses -= 1
		return true
	end

	local emitObjects = {} :: { ParticleEmitter | Sound }
	for _, descendant in emitter:GetDescendants() do
		if descendant:IsA("ParticleEmitter") or descendant:IsA("Sound") then
			table.insert(emitObjects, descendant)
		end
	end

	if #emitObjects <= 0 then
		scope:log({
			"Emitter has no objects to emit.",
			`Path: {emitter:GetFullName()}`,
			type = "warn",
			traceback = 3,
		})
		return
	end
	
	task.spawn(function() --> Preload sounds
		local sounds = {}
		
		for _, emitObject in emitObjects do
			if emitObject:IsA("Sound") then
				table.insert(sounds, emitObject)
			end
		end
		
		ContentProvider:PreloadAsync(sounds)
	end)
	
	local globalSounds = Instance.new("Folder")
	globalSounds.Name = "GlobalSounds"
	globalSounds.Parent = emitter

	local random = Random.new()
	local function emit()
		if emitter:GetAttribute("Activated") == false or cooldownActive or not checkUses() then
			return
		end

		for _, object in emitObjects do
			local emmissionConfig =
				Config.GetConfig(nil, object:FindFirstChild("EmitConfiguration"), EMMISSION_CONFIG_TEMPLATE)
			task.delay(emmissionConfig.EmitDelay, function()
				if object:IsA("ParticleEmitter") then
					local emitCount = emmissionConfig.EmitCount
					if typeof(emitCount) == "NumberRange" then
						emitCount = random:NextInteger(emitCount.Min, emitCount.Max)
					elseif typeof(emitCount) ~= "number" then
						emitCount = 0
					end

					object:Emit(emitCount)
				elseif object:IsA("Sound") then
					local sound = object:Clone()
					
					local pitchRange = emmissionConfig.PitchRange
					if pitchRange and sound.PlaybackSpeed == 1 then
						sound.PlaybackSpeed = 
							random:NextInteger(pitchRange.Min * 100, pitchRange.Max * 100) / 100
					end
					
					sound.Parent = if configuration.GlobalSound then globalSounds else emitter
					sound:Play()
					task.delay(sound.TimeLength / sound.PlaybackSpeed, function()
						sound:Destroy()
					end)
				end
			end)
		end

		if configuration.Cooldown > 0 then
			cooldownActive = true
			task.delay(configuration.Cooldown, function()
				cooldownActive = false
			end)
		end
	end

	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[emitter] = emit
	scope:add(function()
		cache[emitter] = nil
		cache = nil :: any
	end)

	--> Main functionality
	scope:add(emitter.Touched:Connect(function(toucher)
		if not utility.ClientObjects.evaluateToucher(emitter, toucher, touchConfiguration) then
			return
		end

		emit()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(emitter, emit))
	end
end

return Emitter
