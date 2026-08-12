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

-- Preset Sequencer activators . . .

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local _TDefs = require(script.Parent.TypeDefs)
type SequenceData = _TDefs.SequenceData
type ActivatorData = _TDefs.ActivatorData
type SequencerCache = _TDefs.SequencerCache

return function(register, utility: _T.Utility, cache: SequencerCache, scope: _T.Scope)
	-- Damage Brick Activator
	register(
		"DamageBrick",
		{
			priority = nil,
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				if not instance:IsA("BasePart") then
					return false
				end
				local valid = utility.Character.validateDamageBrick(instance) ~= nil
				if valid then
					optimize(instance)
				end
				return valid
			end,
			activate = function(sequenceData)
				if not sequenceData.instance:IsA("BasePart") then
					return
				end
				utility.Character.takeDamage(sequenceData.instance)
			end,
		} :: ActivatorData
	)

	local function runSequence(sequence, variables): string?
		for _, activator in sequence.activators do
			local success, returned: string? = pcall(activator, sequence, variables)
			if (not success) and typeof(returned) == "string" then
				scope:log({ `sequencer error: {returned}` })
            elseif success and returned == "STOP_SEQUENCE" or returned == "BREAK_LOOP" then
				return returned
			end
		end

		return nil
	end

	-- Sequence Pointers
	local pointerName = "SequencePointer"
	local cachedSequenceData = {}
	register(
		pointerName,
		{
			priority = nil,
			check = function(sequenceData, optimize)
				local instance = sequenceData.instance
				local config = instance:FindFirstChild("PointerConfiguration")
				if
					not instance:IsA("BasePart")
					or not config
					or instance.Name:sub(1, pointerName:len()):lower() ~= pointerName:lower()
				then
					return false
				end

				optimize(instance)
				sequenceData.activatorData.pointsTo = config:GetAttribute("Pointer")
				return true
			end,
			activate = function(sequenceData, variables: { [string]: any })
				local tag = sequenceData.activatorData.pointsTo
				for match, replace in variables do
					if typeof(match) ~= "string" or typeof(replace) ~= "string" then
						continue
					end
					tag = tag:gsub(`\{{match}}`, replace)
				end

				for _, object in CollectionService:GetTagged(tag) do
					if not object:IsDescendantOf(scope.clientObjects) or not object:IsA("PVInstance") then
						continue
					end

					local thisSequenceData = cachedSequenceData[object]
					if not thisSequenceData then
						thisSequenceData = cache.makeSequenceData(object, false, true)
						thisSequenceData.activators = cache.fetchActivators(thisSequenceData)
						cachedSequenceData[object] = thisSequenceData
					end

					local result = runSequence(thisSequenceData, variables)
					if result ~= nil then
						return result
					end
				end
			end,
		} :: ActivatorData
	)

	-- Sequencers
	register(
		"Sequencers",
		{
			priority = nil,
			check = function(sequenceData)
				local instance = sequenceData.instance
				if not instance then
					return false
				end

				local activate = cache.sequencers[instance]
				if activate ~= nil then
					sequenceData.activatorData.activateSequence = activate
				end

				return activate ~= nil
			end,
			activate = function(sequenceData, variables)
				local activate = sequenceData.activatorData.activateSequence
				if sequenceData.canAwait then
					activate(variables)
				else
					task.spawn(activate, variables)
				end
			end,
		} :: ActivatorData
	)

	-- Sequence Groups
	local Config = utility.Config
	local Type = Config.Type
	local configTemplate = {
		Mode = Type.Some("Random", "And", "Or", Type.none),
	}

	local RANDOM = Random.new()
    local STOP_CODE = "STOP_SEQUENCE"
    local ALT_STOP_CODE = "BREAK_LOOP"
	register(
		"SequenceGroups",
		{
			priority = nil,
			check = function(sequenceData)
				local instance = sequenceData.instance
				if instance.Name ~= "SequenceGroup" or not instance:IsA("Model") then
					return false
				end

				local groupConfig = instance:FindFirstChild("GroupConfiguration")
				if not groupConfig then
					return false
				end
				local configuration = Config.GetConfig(nil, groupConfig, configTemplate)
				if typeof(configuration.Mode) ~= "string" then
					return false
				end

				local forceAwait = configuration.Mode == "And" or configuration.Mode == "Or"
				sequenceData.canAwait = forceAwait or sequenceData.canAwait

				local groupData = {}
				for _, child: Instance in instance:GetChildren() do
					if not child:IsA("PVInstance") then
						continue
					end

					local newSequenceData = cache.makeSequenceData(child, forceAwait)
					local activators = cache.fetchActivators(newSequenceData)
					if #activators <= 0 then
						continue
					end

					newSequenceData.activators = activators
					table.insert(groupData, newSequenceData)
				end

				local canContinue = #groupData > 0
				if canContinue then
					sequenceData.activatorData.sequenceGroups = { sequences = groupData, mode = configuration.Mode }
				end

				return canContinue
			end,
			activate = function(sequenceData, variables: { [string]: any })
				local data = sequenceData.activatorData.sequenceGroups
				if not data then
					return
				end

				local sequences = data.sequences
				local mode = data.mode
				if mode == "Random" then
					local randomSequence = sequences[RANDOM:NextInteger(1, #sequences)]
					return runSequence(randomSequence, variables)
				elseif mode == "And" or mode == "Or" then
					local threads = {}
					local results = {}
					for _, sequence in sequences do
						table.insert(
							threads,
							task.spawn(function()
								table.insert(results, runSequence(sequence, variables) or "none")
							end)
						)
					end

					--> Wait for threads to complete
					local totalThreads = #threads
					local refresh = 1 / 60
					while true do
						local threadsFinished = 0
						for _, thread in threads do
							if coroutine.status(thread) ~= "dead" then
								continue
							end
							threadsFinished += 1
						end

						if threadsFinished >= totalThreads then
							break
						end
						task.wait(refresh)
					end

					--> (just for safety, cancel threads)
					for _, thread in threads do
						pcall(task.cancel, thread)
					end
					threads = nil :: any

					--> Return Logic
					if mode == "And" then
						for _, result in results do
                            if result == STOP_CODE or result == ALT_STOP_CODE then
                                return result
							end
						end
					elseif mode == "Or" then
                        local finalResult = false
                        local stopCode = ""
						for _, result in results do
                            if result ~= STOP_CODE and result ~= ALT_STOP_CODE then
                                finalResult = true
                            else
                                stopCode = result
							end
						end

                        return if finalResult then nil else stopCode
					end
				end
			end,
		} :: ActivatorData
	)
end
