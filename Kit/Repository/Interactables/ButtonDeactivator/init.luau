--!strict
--!optimize 2
--@version buttondeactivator-6.0.0
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
local SequencerSupport = require(script.SequencerSupport)

local ButtonDeactivator = {
	CanQueue = true,
	RunOnStart = false,
}

local DEACTIVATOR_CONFIG_TEMPLATE = {
	ColorSpecific = false,
}

local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function ButtonDeactivator.Run(scope: _T.Scope, utility: _T.Utility)
	local deactivatorConfig = scope.instance
	if not deactivatorConfig or not deactivatorConfig.Parent or not deactivatorConfig.Parent:IsA("BasePart") then
		return
	end

	local deactivatorPart = deactivatorConfig.Parent
	scope:attach(deactivatorPart)

	local buttonScript = scope.repository["Interactables/Button"]
	if typeof(buttonScript) ~= "table" then
		return -- Button script not used here
	end

	local Communicator = buttonScript.Communicator
	local buttonRequest = scope:getCommunicator("request", Communicator.KEY)
	local buttonCache = buttonRequest:request(Communicator.AWAIT_CACHE)

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, deactivatorConfig, DEACTIVATOR_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, deactivatorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	local debounce = false
	local roundColor = utility.Functions.roundColor
	local function deactivate()
		if debounce or deactivatorPart:GetAttribute("Activated") == false then
			return
		end

		debounce = true
		task.delay(0.25, function()
			debounce = false
		end)

		local deactivatorColor = roundColor(deactivatorPart.Color)
		for _, button in buttonCache.Buttons do
			if not (configuration.ColorSpecific and roundColor(button.Color) ~= deactivatorColor) then
				button.Pressed.Value = false
			end
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[deactivatorPart] = deactivate
	scope:add(function()
		cache[deactivatorPart] = nil
		cache = nil :: any
		buttonCache = nil :: any
	end)

	--> Activation
	scope:add(deactivatorPart.Touched:Connect(function(toucher: BasePart)
		if not utility.ClientObjects.evaluateToucher(deactivatorPart, toucher, touchConfiguration) then
			return
		end

		deactivate()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(deactivatorPart, deactivate))
	end
end

return ButtonDeactivator
