--!strict
--!optimize 2
--@version guidisplayer-6.1.0
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local localPlayer = Players.LocalPlayer

local GuiDisplayer = {
	CanQueue = true,
	RunOnStart = false,
}

local CONFIG_TEMPLATE = {
	Cooldown = 0.25,
}
local DISPLAYER_CONFIG_TEMPLATE = {
	AutoRemove = 0,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {
		wrappers = {},
		container = rootScope:add(Instance.new("Folder")),
	}

	cache.container.Name = "GuiDisplayContainer"
	cache.container.Parent = localPlayer:WaitForChild("PlayerGui")
	rootScope.shared.GuiContainer = cache.container

	SequencerSupport(rootScope, utility, cache)
	return cache
end

function GuiDisplayer.Run(scope: _T.Scope, utility: _T.Utility)
	local displayerConfig = scope.instance
	if not displayerConfig or not displayerConfig.Parent then
		return
	end

	local gui = displayerConfig:FindFirstChildWhichIsA("ScreenGui")
	if not gui then
		return
	end

	local Config = utility.Config
	local displayerConfiguration = Config.GetConfig(scope, displayerConfig, CONFIG_TEMPLATE)

	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)

	scope:add(gui)
	gui.Parent = nil

	local currentlyDisplaying: ScreenGui?
	local cooldown = false
	local displayScope = scope:inherit()
	local function remove()
		if not currentlyDisplaying then
			return
		end

		displayScope:cleanup(true)
		currentlyDisplaying = nil
	end

	local function display(autoRemove: number?)
		if currentlyDisplaying or cooldown then
			return
		end
		displayScope:cleanup()
		cooldown = true
		task.delay(displayerConfiguration.Cooldown, function()
			cooldown = false
		end)

		currentlyDisplaying = displayScope:add(gui:Clone())
		if not currentlyDisplaying then -- this is for type checking
			return
		end

		currentlyDisplaying.Parent = cache.container
		if typeof(autoRemove) == "number" and autoRemove > 0 then
            task.wait(autoRemove) -- @v6.0.1 fix
			remove()
		end
	end

	scope:attach(displayerConfig)
	for _, part in displayerConfig.Parent:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		scope:attach(part)
		
		local displayerConfigObject = part:FindFirstChild("DisplayerConfiguration") or part:FindFirstChild("RemoverConfiguration")
		local touchConfiguration =
			Config.GetConfig(scope, displayerConfigObject:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()

		local wrapper
		if (part.Name == "Displayer" or part:HasTag("GuiDisplayer")) and not currentlyDisplaying and not cooldown then
			--> Displayer Parts
			local displayConfig =
				Config.GetConfig(scope, displayerConfigObject, DISPLAYER_CONFIG_TEMPLATE)
					:ObserveChanges()

			function wrapper()
				if currentlyDisplaying or cooldown or part:GetAttribute("Activated") == false then
					return
				end
				display(displayConfig.AutoRemove)
			end
		elseif part.Name == "Remover" or part:HasTag("GuiRemover") then
			--> Remover Parts
			wrapper = remove
		end

		--> Sequencer Cache Support
		cache.wrappers[part] = wrapper
		scope:add(function()
			if not cache then
				return
			end
			cache.wrappers[part] = nil
			cache = nil :: any
		end)

		--> Activation
		scope:add(part.Touched:Connect(function(toucher)
			if not utility.ClientObjects.evaluateToucher(part, toucher, touchConfiguration) then
				return
			end

			wrapper()
		end))

		if touchConfiguration.canFlip then
			scope:add(utility.ClientObjects.bindToFlip(part, wrapper))
		end
	end
end

return GuiDisplayer
