--!strict
--!optimize 2
--@version movingplatform-6.0.0
--@creator aamo_s, synnwave
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
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

local MovingPlatform = {
	CanQueue = true,
	RunOnStart = false,
}

local PLATFORM_CONFIG_TEMPLATE = {
	TouchActivated = false,
	Tween = false,
}

function MovingPlatform.Run(scope: _T.Scope, utility: _T.Utility)
	local movingPlatformConfig = scope.instance
	if not movingPlatformConfig then
		return
	end

	local model = movingPlatformConfig.Parent
	if not model then
		return
	end

	--> Get Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, movingPlatformConfig, PLATFORM_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, movingPlatformConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	--> Setup Platform
	local platform = nil
	for _, v in model:GetChildren() do
		if not v:IsA("BasePart") or v.Name ~= "Platform" then
			continue
		end

		if platform then
			scope:log({
				`{model:GetFullName()} has multiple 'Platform' objects. There should only be one.`,
				type = "error",
				printType = "warn",
				traceback = false,
			})

			return
		end

		platform = v
	end

	local platformAttachment = platform:FindFirstChildOfClass("Attachment")
	local positions = model:FindFirstChild("Positions")
	local alignOrientation = platform:FindFirstChildOfClass("AlignOrientation")
	local alignPosition = platform:FindFirstChildOfClass("AlignPosition")
	if not platformAttachment or not positions or not alignOrientation or not alignPosition then
		return
	end

	--> Setup Positions
	local positionAttachments = {}
	for _, position in positions:GetChildren() do
		local attachment = position:FindFirstChildOfClass("Attachment")
		local positionNumber = tonumber(position.Name:match("%d+"))
		if not position:IsA("BasePart") or not attachment or not positionNumber then
			continue
		end

		local configObject = position:FindFirstChild("PositionConfiguration")
		local positionConfiguration = Config.GetConfig(scope, configObject, { MoveDelay = 2 }):ObserveChanges()
		local tweenConfiguration = Config.GetConfig(
			scope,
			configObject and configObject:FindFirstChild("TweenConfiguration"),
			Config.TWEEN_CONFIG
		):ObserveChanges()

		positionAttachments[positionNumber] = {
			attachment = attachment,
			config = positionConfiguration,
			tweenInfo = tweenConfiguration,
		}
	end

	if not next(positionAttachments) then
		return
	end

	local firstPosition = positionAttachments[1]
	alignPosition.Attachment0 = platformAttachment
	alignOrientation.Attachment0 = platformAttachment
	alignPosition.Position = firstPosition.attachment.CFrame.Position
	alignOrientation.CFrame = firstPosition.attachment.CFrame

	--> Main Functionality
	local currentPositionNumber = 0
	local function moveToNextPosition()
		local positionNumbers = {}
		local hasNotLooped = true

		for number in positionAttachments do
			table.insert(positionNumbers, number)
		end

		table.sort(positionNumbers)

		local nextPosition = nil
		for i, number in positionNumbers do
			if number > currentPositionNumber then
				nextPosition = number
				break
			end
		end

		if not nextPosition then
			nextPosition = positionNumbers[1]
			hasNotLooped = false
		end

		if positionAttachments[nextPosition] then
			currentPositionNumber = nextPosition

			local nextData = positionAttachments[nextPosition]
			local nextCFrame = nextData.attachment.WorldCFrame
			if configuration.Tween then
				utility.Functions.tween(alignOrientation, nextData.tweenInfo, { CFrame = nextCFrame })
				utility.Functions
					.tween(alignPosition, nextData.tweenInfo, { Position = nextCFrame.Position }).Completed
					:Wait()
			else
				alignPosition.Position = nextCFrame.Position
				alignOrientation.CFrame = nextCFrame
			end

			task.wait(nextData.config.MoveDelay)
		else
			scope:log({
				`{movingPlatformConfig:GetFullName()} has no position to go to!`,
				type = "error",
				printType = "warn",
				traceback = false,
			})
		end

		return hasNotLooped
	end

	--> Activation
	moveToNextPosition()
	platform.Anchored = false

	scope:attach(platform)
	scope:delay(firstPosition.config.MoveDelay, function()
		while platform and platform.Parent and not configuration.TouchActivated do
			moveToNextPosition()
		end
	end)

	local active = false
	local function activate()
		if active then
			return
		end
		local looping = true
		active = true
		repeat
			looping = moveToNextPosition()
		until not looping
		active = false
	end
	scope:add(platform.Touched:Connect(function(touchingPart)
		if
			not configuration.TouchActivated
			or active
			or not utility.ClientObjects.evaluateToucher(platform, touchingPart, touchConfiguration)
		then
			return
		end

		activate()
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(platform, activate))
	end
end

return MovingPlatform
