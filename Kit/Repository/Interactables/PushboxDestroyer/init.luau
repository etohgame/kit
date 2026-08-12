--!strict
--!optimize 2
--@version pushboxdestroyer-6.0.0
--@creator Camille
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

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local PushboxDestroyer = {
	CanQueue = true,
	RunOnStart = false,
}

local DESTROYER_CONFIG_TEMPLATE = {
	DestroyWholeModel = false,
	ColorSpecific = false,
	DestroyTag = "",
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [BasePart]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function PushboxDestroyer.Run(scope: _T.Scope, utility: _T.Utility)
	local Config = utility.Config

	local destroyerConfig = scope.instance
	if not destroyerConfig or not destroyerConfig.Parent then
		return
	end

	--> Setup
	local destroyer = destroyerConfig.Parent
	if not destroyer:IsA("BasePart") then
		scope:log({
			"This PushboxDestroyer is set up incorrectly and will not function, it must be a Part.",
			`Path: {destroyer:GetFullName()}`,
			type = "warn",
		})

		return
	end

	local configuration = Config.GetConfig(scope, destroyerConfig, DESTROYER_CONFIG_TEMPLATE):ObserveChanges()

	--> Destroyer functionality
	local function destroy(box: Model | BasePart)
		if utility.ClientObjects.isPushbox(box) then
			if box:IsA("BasePart") and configuration.ColorSpecific then
				local boxColor = utility.Functions.roundColor(box.Color)
				local destroyerColor = utility.Functions.roundColor(destroyer.Color)

				if boxColor ~= destroyerColor then
					return
				end
			end

			if configuration.DestroyWholeModel then
				local model = box:FindFirstAncestor("Pushbox")
				if model then
					model:Destroy()
				end
			else
				box:Destroy()
			end
		end
	end

	local function destroyTagged()
		local clientObjects = scope.clientObjects
		if configuration.DestroyTag ~= "" then
			for _, otherPart in CollectionService:GetTagged(configuration.DestroyTag) do
				if otherPart:IsDescendantOf(clientObjects) then
					destroy(otherPart)
				end
			end
		end
	end

	scope:attach(destroyer)
	scope:add(destroyer.Touched:Connect(function(otherPart: BasePart)
		destroy(otherPart)
		destroyTagged()
	end))

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[destroyer] = destroyTagged
	scope:add(function()
		cache[destroyer] = nil
		cache = nil :: any
	end)
end

return PushboxDestroyer
