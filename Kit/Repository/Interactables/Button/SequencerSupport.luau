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
type Button = _TDefs.Button<any>
type ButtonCache = _TDefs.ButtonCache<any, any>

return function(rootScope: _T.Scope, utility: _T.Utility, cache: ButtonCache)
	local clientObjectUtil = utility.ClientObjects
	local sequencerScript = rootScope.repository["Interactables/Sequencer"]
	if typeof(sequencerScript) ~= "table" or not sequencerScript.Communicator then
		return
	end

	local SequencerCommunicator = sequencerScript.Communicator
	local sequencerRequest = rootScope:getCommunicator("request", SequencerCommunicator.KEY)

	rootScope:spawn(utility.Functions.yieldTimeout, 5, function()
		--> BAP support
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "ButtonActivatedPlatforms", {
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				if not instance or not instance:IsA("BasePart") then
					return false
				end
				local isButtonActivated = clientObjectUtil.isButtonActivatedPlatform(instance)
				if isButtonActivated then
					sequenceData.canAwait = true -- Force Yield Mode
					optimize(instance)
				end

				return isButtonActivated
			end,
			activate = function(sequenceData)
				local instance = sequenceData.instance
				while not instance:GetAttribute("Activated") do
					task.wait()
				end
			end,
		})

		--> Button support
		sequencerRequest:request(SequencerCommunicator.REGISTER_OBJECT, "Buttons", {
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				if not instance then
					return false
				end
				local buttonPart = instance:FindFirstChild("ButtonPart")
				if not buttonPart then
					return false
				end

				local buttonData = cache.Buttons[buttonPart]
				if buttonData ~= nil then
					sequenceData.activatorData.ButtonData = buttonData
					optimize(buttonData.Button)
				end

				return buttonData ~= nil
			end,
			activate = function(sequenceData)
				local buttonData = sequenceData.activatorData.ButtonData
				buttonData.Pressed.Value = true
				if sequenceData.canAwait then
					buttonData.Pressed:GetPropertyChangedSignal("Value"):Wait()
				end
			end,
		})

		--> Cleanup
		sequencerScript = nil :: any
		sequencerRequest = nil :: any
		SequencerCommunicator = nil :: any
	end)
end
