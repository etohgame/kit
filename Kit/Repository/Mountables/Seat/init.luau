--!strict
--!optimize 2
--@version seat-6.1.3
--@creator Gammattor
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

local Seat = {
	CanQueue = true,
	RunOnStart = false,
}

local SEAT_CONFIG_TEMPLATE = {
	Cooldown = 1,
	SitOffset = CFrame.identity,
}

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

local player = Players.LocalPlayer
function Seat.Run(scope: _T.Scope, utility: _T.Utility)
	local JumpButton = utility.JumpButton
	local seatConfig = scope.instance
	if not seatConfig then
		return
	end

	local seat = seatConfig.Parent
	if not seat or not seat:IsA("BasePart") then
		return
	end

	if not scope.shared.mountedCOs then
		scope.shared.mountedCOs = {}
	end
	local mountedCOs = scope.shared.mountedCOs :: { [BasePart]: { [Instance]: string } }

	local Config = utility.Config
	local configuration = Config.GetConfig(scope, seatConfig, SEAT_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, seatConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()
	------------------------------------------------------------------------
	--> Mount seat
	local seatDebounce = false
	local seatScope = scope:inherit()

	local function sit()
		if seatDebounce or seat:GetAttribute("Activated") == false then
			return
		end
		local characterInstances = utility.Character.getCharacter()
		local rootPart = characterInstances.rootPart
		local humanoid = characterInstances.humanoid
		if not rootPart or not humanoid then
			return
		end

		if mountedCOs[rootPart] then
			for _, mountName in mountedCOs[rootPart] do
				if mountName == "Seat" then
					return
				end
			end
		else
			mountedCOs[rootPart] = {}
		end
		mountedCOs[rootPart][seat] = "Seat"
		seatDebounce = true

		humanoid.Sit = true
		rootPart.CFrame = (seat.CFrame + seat.CFrame.UpVector * (seat.Size.Y / 2 + 1.5)) * configuration.SitOffset

		local seatWeld = Instance.new("WeldConstraint")
		seatWeld.Parent = seat
		seatWeld.Part0 = seat
		seatWeld.Part1 = rootPart

		------------------------------------------------------------------------
		--> Dismount function
		local function dismountSeat()
			seatScope:cleanup(true)
			if seatWeld then
				seatWeld:Destroy()
			end

			if mountedCOs[rootPart] and mountedCOs[rootPart][seat] then
				mountedCOs[rootPart][seat] = nil
				if utility.Table.IsEmpty(mountedCOs[rootPart]) then
					mountedCOs[rootPart] = nil
				end
			end

			rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(rootPart.Orientation.Y), 0)
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

			task.delay(configuration.Cooldown, function()
				seatDebounce = false
			end)
		end

		if JumpButton.IsDown() then
			dismountSeat()
		end

		seatScope:add(JumpButton.JumpEvent.Event:Connect(function(isPressed: boolean)
			if not isPressed then
				return
			end
			dismountSeat()
		end))

		seatScope:spawn(function()
			while task.wait(1 / 60) do
				debug.profilebegin("Seat Checking")
				if not (mountedCOs[rootPart] and mountedCOs[rootPart][seat]) then
					dismountSeat()
					break
				end
				debug.profileend()
			end
		end)
	end

	--> Activation
	scope:add(seat.Touched:Connect(function(touch)
		if not (touchConfiguration.player and table.find(utility.Character.getHitbox("StaticWholeBody"), touch)) then
			return
		end

		sit()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(seat, sit))
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[seat] = sit
	scope:add(function()
		cache[seat] = nil
		cache = nil :: any
	end)
end

return Seat
