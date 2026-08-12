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

return function(rootScope: _T.Scope, utility: _T.Utility, cache: any)
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	rootScope:spawn(utility.Functions.yieldTimeout, 5, function()
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "Morpher", {
			check = function(sequenceData, optimize)
				local instance: Instance = sequenceData.instance
				local foundMorpherButton
				for id, buttons in cache.morpherButtons do
					for _, button in buttons do
						if button.button == instance then
							foundMorpherButton = button
						end
					end
				end

				if foundMorpherButton then
					optimize(instance)
					sequenceData.activatorData.MorpherButton = foundMorpherButton
				end

				return foundMorpherButton ~= nil
			end,
			activate = function(sequenceData)
				local morpherActivate = sequenceData.activatorData.MorpherButton.activate
				if typeof(morpherActivate) == "function" then
					if sequenceData.canAwait then
						morpherActivate()
					else
						task.spawn(morpherActivate)
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
