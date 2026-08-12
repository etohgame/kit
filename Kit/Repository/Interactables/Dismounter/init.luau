--!strict
--!optimize 2
--@version dismounter-6.1.3
--@creator Gammattor
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _T = require(ReplicatedStorage.Framework.ClientTypes)
local SequencerSupport = require(script.SequencerSupport)

local mountPartNames = {
	["Zipline"] = "MountPart",
	["Balloon"] = "Dispenser",
	["Vine"] = "VinePart",
	["Swing"] = "Handle",
	["Attacher"] = "Trigger",
}

local Dismounter = {
	CanQueue = true,
	RunOnStart = false,
}

local DISMOUNTER_CONFIG_TEMPLATE = {
	Cooldown = 0,
	MountColorSpecific = false,
	ForceDismountPlayer = false,
}

local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: (touch: BasePart) -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function Dismounter.Run(scope: _T.Scope, utility: _T.Utility)
	local dismounterConfig = scope.instance
	if not dismounterConfig or not dismounterConfig.Parent or not dismounterConfig.Parent:IsA("BasePart") then
		return
	end
	local dismounter = dismounterConfig.Parent

	--> Get Mount parts cache
	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, dismounterConfig, DISMOUNTER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, dismounterConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	local dismounterDebounce = false
	local function dismount(touch: BasePart?)
		if not touch or dismounterDebounce or dismounter:GetAttribute("Activated") == false then
			return
		end

		local characterInstances = utility.Character.getCharacter()
		local character = characterInstances.character
		local humanoid = characterInstances.humanoid
		local rootPart = characterInstances.rootPart
		if not rootPart then
			return
		end

		if utility.ClientObjects.isBalloon(touch) then
			local attachedToValue = touch:FindFirstChild("_AttachedTo") :: ObjectValue
			if attachedToValue and attachedToValue.Value and attachedToValue.Value:IsA("BasePart") then
				touch = attachedToValue.Value
			else
				return
			end
		end

		local setDebounce = false
		local isBox = utility.ClientObjects.isPushbox(touch)
		local attachedRoot = if isBox then touch else rootPart

		local attributes = dismounterConfig:GetAttributes()
		local function checkAttached(attached: BasePart)
			if not mountedCOs[attached] then
				return
			end

			for model, name in mountedCOs[attached] do
				if not attributes[`Dismount{name}s`] then
					continue
				end

				if configuration.MountColorSpecific then
					local mountPartName = mountPartNames[name]
					local mountPart = if model:IsA("BasePart")
						then model
						else model:FindFirstChild(mountPartName) :: BasePart

					if mountPart and mountPart.Color ~= dismounter.Color then
						continue
					end
				end

				setDebounce = true
				mountedCOs[attached][model] = nil
				if utility.Table.IsEmpty(mountedCOs[attached]) then
					mountedCOs[attached] = nil
					break
				end
			end
		end

		checkAttached(attachedRoot)
		if attachedRoot:IsDescendantOf(character) or configuration.ForceDismountPlayer then
			--> Check for any parts mounted to other limbs
			for _, part in character:GetChildren() do
				if not part:IsA("BasePart") or part == attachedRoot then
					continue
				end
				checkAttached(part)
			end
		end

		if setDebounce then
			dismounterDebounce = true
			task.delay(configuration.Cooldown, function()
				dismounterDebounce = false
			end)
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[dismounter] = dismount
	scope:add(function()
		cache[dismounter] = nil
		cache = nil :: any
		mountedCOs = nil :: any
	end)

	--> Activation
	scope:add(dismounter.Touched:Connect(function(touch)
		if not utility.ClientObjects.evaluateToucher(dismounter, touch, touchConfiguration) then
			return
		end

		dismount(touch)
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(dismounter, dismount))
	end
end

return Dismounter
