--!strict
--!optimize 2
--@version fallingplatform-6.1.0
--@creator Camille, synnwave
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

local RELEASE_FORCE = Vector3.one * math.huge
local RELEASE_VELOCITY = math.huge

local FallingPlatform = {
	CanQueue = true,
	RunOnStart = false,
}

local PLATFORM_CONFIG_TEMPLATE = {
	ActiveTime = 1.5,
	ActiveTransparency = 0.75,
	BaseMass = 12.6, -- :goldenmass: twk twk
	ActivateConnectedParts = true,
	ActiveCanCollide = false,
}

type FallingPart = {
	part: BasePart,
	transparency: number,
	canCollide: boolean,
}

function FallingPlatform.Run(scope: _T.Scope, utility: _T.Utility)
	local fallingPlatformConfig = scope.instance
	if not fallingPlatformConfig then
		return
	end

	local fallingPlatform = fallingPlatformConfig.Parent
	if not fallingPlatform then
		return
	end

	--> Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, fallingPlatformConfig, PLATFORM_CONFIG_TEMPLATE):ObserveChanges()

	--> Setup and check for problems
	local platform = fallingPlatform:FindFirstChild("Platform")
	if not platform or not platform:IsA("BasePart") then
		scope:log({
			"FallingPlatform is either missing its Platform part or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local endPart = fallingPlatform:FindFirstChild("End")
	if not endPart or not endPart:IsA("BasePart") then
		scope:log({
			"FallingPlatform is either missing its End part or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end

	local alignPosition = platform:FindFirstChildWhichIsA("AlignPosition")
	local attachment = platform:FindFirstChildWhichIsA("Attachment")
	if not alignPosition or not attachment then
		scope:log({
			"FallingPlatform is either missing its AlignPosition or has it set up incorrectly.",
			`Path: {fallingPlatform:GetFullName()}`,
			type = "warn",
		})
		return
	end
	alignPosition.Attachment0 = attachment
	alignPosition.Enabled = true

	--> Setup platform part and connected parts
	local oldPhysicalProperties = platform.CustomPhysicalProperties or platform.CurrentPhysicalProperties
	platform.CustomPhysicalProperties = PhysicalProperties.new(
		(1 / (platform.Mass * oldPhysicalProperties.Density)) * configuration.BaseMass,
		oldPhysicalProperties.Friction,
		oldPhysicalProperties.Elasticity,
		oldPhysicalProperties.FrictionWeight,
		oldPhysicalProperties.ElasticityWeight
	)

	alignPosition.MaxAxesForce = Vector3.yAxis * ((workspace.Gravity * platform.Mass) + 58)
	alignPosition.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	alignPosition.ForceRelativeTo = Enum.ActuatorRelativeTo.World
	alignPosition.Position = platform.Position
	platform.Anchored = false
	
	local buttonCache = nil
	local buttonActivated = platform:HasTag("ButtonActivated")
	local platformColor = utility.Functions.roundColor(
		platform:GetAttribute("ColorOverride") or platform.Color
	)

	local connectedParts = platform:GetConnectedParts(true)
	local partTable: {FallingPart} = {}
	
	do
		local buttonScript = scope.repository["Interactables/Button"]
		if typeof(buttonScript) ~= "table" then
			return -- Button script not used here
		end

		local Communicator = buttonScript.Communicator
		local buttonRequest = scope:getCommunicator("request", Communicator.KEY)
		buttonCache = buttonRequest:request(Communicator.AWAIT_CACHE)
	end
	
	local function isButtonActivated(color: Color3): boolean
		if not buttonCache then
			return false
		end
		
		for _, button in buttonCache.Buttons do
			if
				platformColor == utility.Functions.roundColor(button.Color)
				and button.Pressed.Value
			then
				return true
			end
		end
		
		return false
	end

	for _, part in connectedParts do
		if part ~= platform then
			part.Massless = true

			if not configuration.ActivateConnectedParts then
				continue
			end
		end
		
		local realTransparency = if buttonActivated
			then utility.Functions.getButtonActivatedTransparency(part, not part:HasTag("Invert"))
			else part.Transparency
		
		table.insert(partTable, {
			part = part,
			transparency = part.Transparency,
			canCollide = part.CanCollide,
		})
	end

	--> Functions
	local oldForce = alignPosition.MaxAxesForce
	local oldVelocity = alignPosition.MaxVelocity
	local active = false
	local function activate(activeTime: number)
		active = true

		for _, part in partTable do
			part.part.CanCollide = configuration.ActiveCanCollide
			part.part.Transparency = configuration.ActiveTransparency
		end

		alignPosition.MaxAxesForce = RELEASE_FORCE
		alignPosition.MaxVelocity = RELEASE_VELOCITY

		task.wait(activeTime)
		
		local buttonActive = isButtonActivated(platformColor)
		for _, part in partTable do
			-- get cancollide
			local realCanCollide = if buttonActivated
				then buttonActive
				else part.canCollide
			
			if part.part:HasTag("Invert") then
				realCanCollide = not realCanCollide
			end
			
			-- get transparency
			local realTransparency = if buttonActivated
				then utility.Functions.getButtonActivatedTransparency(part.part, buttonActive)
				else part.transparency
			
			part.part.CanCollide = realCanCollide
			part.part.Transparency = realTransparency
		end

		alignPosition.MaxAxesForce = oldForce
		alignPosition.MaxVelocity = oldVelocity

		active = false
	end

	--> Main functionality
	scope:attach(fallingPlatform)
	if not buttonActivated then
		scope:spawn(activate, 0.5) -- fix for it getting stuck
	end
	scope:add(endPart.Touched:Connect(function(toucher)
		if toucher == platform and not active then
			activate(configuration.ActiveTime)
		end
	end))
end

return FallingPlatform
