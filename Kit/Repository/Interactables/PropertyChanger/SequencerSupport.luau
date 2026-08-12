--!strict
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
local _TDefs = require(script.Parent.TypeDefs)

return function(rootScope: _T.Scope, utility: _T.Utility, cache: _TDefs.Cache)
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	rootScope:spawn(utility.Functions.yieldTimeout, 5, function()
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "PropertyChanger", {
			check = function(sequenceData, optimize)
				if not sequenceData.instance:IsA("BasePart") then
					return false
				end
				local changer = cache.changers[sequenceData.instance]
				if changer ~= nil then
					if changer.forceAwait then
						sequenceData.canAwait = true
					end
					optimize(sequenceData.instance)
				end

				return changer ~= nil
			end,
			activate = function(sequenceData, variables)
				local changerFn = cache.changers[sequenceData.instance].change
				if typeof(changerFn) == "function" then
					if sequenceData.canAwait then
						return changerFn(variables.TouchingPart, variables)
					else
						task.spawn(changerFn, variables.TouchingPart, variables)
					end
				end
			end,
		})

		--> Cleanup
		sequencerScript = nil :: any
		sequencerRequest = nil :: any
		SequencerCommunicator = nil :: any
	end)
end
