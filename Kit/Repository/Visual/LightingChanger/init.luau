--!strict
--!optimize 2
--@version lightingchanger-6.0.0
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

local VALID_CHANGER_PREFIXES = {
	PlaceDefault = true,
	TowerDefault = true,
}

local LightingChanger = {
	CanQueue = true,
	RunOnStart = false,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function LightingChanger.Run(scope: _T.Scope, utility: _T.Utility)
	local changerConfig = scope.instance
	if not changerConfig or not changerConfig.Parent then
		return
	end

	local Config = utility.Config

	--> Check for misconfigurations
	local changer = changerConfig.Parent
	if not changer:IsA("BasePart") then
		scope:log({
			"Changer must be a BasePart",
			`Path: {changer:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	--> Get Lighting Module
	local lightingPointer = utility.Instance.getPointer(changerConfig:FindFirstChild("Lighting"))
	if not lightingPointer or not lightingPointer:IsA("ModuleScript") then
		scope:log({
			"Lighting Changer is missing its 'Lighting' module.",
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
		return
	end

	local lightingData = require(lightingPointer) :: any
	if typeof(lightingData) ~= "table" then
		scope:log({
			`Lighting Changer's lighting module returned "{typeof(lightingData)}", expected table`,
			`Path: {changerConfig:GetFullName()}`,
			traceback = 3,
			type = "warn",
		})
	end

	--> Setup Lighting Configuration
	if lightingData[1] == nil then
		-- To make things a little easier later on, wrap the config in a table
		lightingData = { lightingData }
	end
	if #lightingData > 0 then
		-- Validate multi lighting changer config
		local tweenInfo = lightingData.TweenInfo
		local useDefault = lightingData.UseDefault
		local setDefault = lightingData.SetDefault

		for i, changer in lightingData do
			if typeof(i) ~= "number" then
				lightingData[i] = nil -- Not a lighting config, remove
				continue
			end

			-- Validate the lighting config
			if typeof(changer) ~= "table" or typeof(changer.Type) ~= "string" then
				scope:log({
					"Malformed lighting changer config",
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end

			-- Set Properties
			if tweenInfo ~= nil and changer.TweenInfo == nil then
				changer.TweenInfo = tweenInfo
			end
			if useDefault ~= nil and changer.UseDefault == nil then
				changer.UseDefault = useDefault
			end
			if setDefault ~= nil and changer.SetDefault == nil then
				changer.SetDefault = setDefault
			end

			if changer.UseDefault and not VALID_CHANGER_PREFIXES[changer.UseDefault:sub(1, 12)] then
				scope:log({
					`Malformed lighting changer config (UseDefault = {changer.UseDefault})`,
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end
			if changer.SetDefault and not VALID_CHANGER_PREFIXES[changer.SetDefault:sub(1, 12)] then
				scope:log({
					`Malformed lighting changer config (SetDefault = {changer.SetDefault})`,
					`Path: {changerConfig:GetFullName()}`,
					traceback = 3,
					type = "warn",
				})
				lightingData[i] = nil
				continue
			end
		end
	end

	--> Main Functionality
	local debounce = false
	local function changeLighting()
		if debounce or changer:GetAttribute("Activated") == false then
			return
		end

		debounce = true
		task.delay(0.25, function()
			debounce = false
		end)

		for _, lighting in lightingData do
			utility.Lighting.changeLighting(lighting, scope)
		end

		local lightingTween = if lightingData[1] then lightingData[1].TweenInfo else nil
		task.wait(if lightingTween then lightingTween.Time else 1)
	end

	--> Activation
	local touchConfiguration =
		Config.GetConfig(scope, changerConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	scope:attach(changer)
	scope:add(changer.Touched:Connect(function(toucher: BasePart)
		if not utility.ClientObjects.evaluateToucher(changer, toucher, touchConfiguration) then
			return
		end

		changeLighting()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(changer, changeLighting))
	end

	if changerConfig:GetAttribute("ChangeOnLoad") then
		scope:defer(changeLighting)
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[changer] = changeLighting
	scope:add(function()
		cache[changer] = nil
		cache = nil :: any
	end)
end

return LightingChanger
