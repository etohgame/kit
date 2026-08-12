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

return function(rootScope: _T.Scope, utility: _T.Utility, cache: { wrappers: { [BasePart]: () -> () } })
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)
	rootScope:spawn(utility.Functions.yieldTimeout, 5, function()
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "GuiDisplayer", {
			check = function(sequenceData, optimize)
				local part = sequenceData.instance
				if not part:IsA("BasePart") then
					return false
				end

				local inCache = cache.wrappers[part] ~= nil
				if inCache then
					optimize(part)
				end
				return inCache
			end,
			activate = function(sequenceData)
				local wrapperFn = cache.wrappers[sequenceData.instance]
				if typeof(wrapperFn) == "function" then
					if sequenceData.canAwait then
						wrapperFn()
					else
						task.spawn(wrapperFn)
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
