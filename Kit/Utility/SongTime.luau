--!strict
--[[
--------------------------------------------------------------------------------
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
⚠️  WARNING - PLEASE READ! ⚠️
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

If you are submitting to EToH: 
PLEASE, **DO NOT** make any script edits to this script. 
This is a core script and any edits you make to this script will NOT work 
elsewhere.

If you have any suggestions, please let us know.
Thank you
--------------------------------------------------------------------------------
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SongTime = {}

local TableUtil = require(script.Parent.Table)
local Log = require(ReplicatedStorage.Framework.Log)

export type BPMChange = { beat: number, bpm: number }
export type Stop = { beat: number, seconds: number }
--export type Signature = { beat: number, bottom: number, top: number }
export type SyncModule = {
	TimingOffset: number,
	--TimeSignature: { Signature },
	BeatsPerMinute: { BPMChange },
	Stops: { Stop },
}

type beatCacheItem = {
	beat: number,
	bpm: number,
	second: number,
	secondBefore: number,
	secondAfter: number,
	secondClamped: number,
}

local function binarySearch(array: any, value, index): number
	local low = 1
	local high = #array
	while low <= high do
		local middleIndex = (low + high) // 2
		local middleValue = array[middleIndex][index]
		if middleValue < value then
			low = middleIndex + 1
		elseif middleValue > value then
			high = middleIndex - 1
		else
			return middleIndex
		end
	end

	return math.max(high, 0)
end

local Methods = {
	BeatFromSecond = function(self: MethodCache, seconds: number)
		local index = binarySearch(self.beat, seconds, "secondClamped")
		local thisEvent = self.beat[index] :: beatCacheItem

		local difference = math.max(seconds - thisEvent.secondAfter, 0)
		return thisEvent.beat + (difference * thisEvent.bpm) / 60
	end,

	SecondsFromBeat = function(self: MethodCache, beat: number)
		local floored = (beat * 48) // 48
		local index = binarySearch(self.beat, floored, "beat")
		local thisEvent = self.beat[index] :: beatCacheItem
		if thisEvent.beat == floored then
			return thisEvent.second
		end

		local elapsed = ((beat - thisEvent.beat) * 60) / thisEvent.bpm
		return math.max(thisEvent.secondClamped, thisEvent.secondAfter + elapsed)
	end,
}
Methods.__index = Methods

type MethodCache = typeof(setmetatable({} :: { beat: { beatCacheItem } }, Methods))

-- credits to SMEditor for the code inspo!!
function SongTime.BuildSyncCache(data: SyncModule): MethodCache?
	if not data.BeatsPerMinute or not data.TimingOffset then
		Log({
			"No BPM data found in SongTimeConfiguration",
			type = "warn",
		})
		return
	end

	if not data.BeatsPerMinute[1] or data.BeatsPerMinute[1].beat ~= 0 then
		Log({
			"BPM must be set at beat 0",
			type = "warn",
		})
		return
	end

	--> Get & sort BPM and Stop events
	local events = TableUtil.Extend(data.BeatsPerMinute, data.Stops)
	table.sort(events, function(a, b)
		return a.beat < b.beat
	end)

	local offset = data.TimingOffset
	local beatCache = {} :: { beatCacheItem }
	local fallbackEvent = { secondClamped = -offset, secondAfter = -offset }

	--> Build Beat Cache
	table.insert(beatCache, {
		beat = 0,
		bpm = data.BeatsPerMinute[1].bpm,
		second = -offset,
		secondBefore = -offset,
		secondAfter = -offset,
		secondClamped = -offset,
	})

	for i, event: any in ipairs(events) do
		local lastEvent = beatCache[#beatCache]
		if lastEvent and lastEvent.beat ~= event.beat then
			local secondLastEvent = beatCache[#beatCache - 1] or fallbackEvent
			lastEvent.secondClamped =
				math.max(math.max(secondLastEvent.secondClamped, secondLastEvent.secondAfter), lastEvent.secondBefore)

			local thisSecond = lastEvent.secondAfter + ((event.beat - lastEvent.beat) * 60) / lastEvent.bpm
			table.insert(beatCache, {
				beat = event.beat,
				bpm = lastEvent.bpm,
				second = thisSecond,
				secondBefore = thisSecond,
				secondAfter = thisSecond,
				secondClamped = 0,
			})
		end

		lastEvent = beatCache[#beatCache]
		if event.seconds and lastEvent then -- stop event
			lastEvent.secondAfter += event.seconds
		elseif event.bpm and lastEvent then -- bpm event
			lastEvent.bpm = event.bpm
		end
	end

	local lastEvent = beatCache[#beatCache]
	local secondLastEvent = beatCache[#beatCache - 1] or fallbackEvent
	lastEvent.secondClamped = math.max(lastEvent.secondBefore, secondLastEvent.secondClamped)

	-- TODO: Time signatures
	-- due to time constraints this will have to be done later

	return setmetatable({ beat = beatCache }, Methods)
end

return table.freeze(SongTime)
