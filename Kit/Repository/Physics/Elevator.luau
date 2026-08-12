--!strict
--!optimize 2
--@version elevator-6.1.1
--@creator synnwave
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
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local UPDATE_INTERVAL = 1 / 60
local ALLOWED_CFRAME_COMPONENTS = {
	"UpVector",
	"RightVector",
	"LookVector",
	"ZVector",

	"WorldYVector",
}
local WORLD_CFRAME_COMPONENTS = {
	WorldYVector = Vector3.yAxis,
}

local Elevator = {
	CanQueue = true,
	RunOnStart = false,
}

local ELEVATOR_CONFIG_TEMPLATE
function Elevator.Init(utility: _T.Utility)
	local Config = utility.Config
	ELEVATOR_CONFIG_TEMPLATE = {
		MaxForce = math.huge,
		Speed = 40,
		Vector = Config.Type.Some(table.unpack(ALLOWED_CFRAME_COMPONENTS)),
		ContinuousUpdates = false,
	}
end

local localPlayer = Players.LocalPlayer
function Elevator.Run(scope: _T.Scope, utility: _T.Utility)
	local elevatorConfig = scope.instance
	if not elevatorConfig then
		return
	end

	local elevator = elevatorConfig.Parent
	if not elevator or not elevator:IsA("BasePart") then
		return
	end

	--> Get Config
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, elevatorConfig, ELEVATOR_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, elevatorConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()

	--> Main Functionality
	local touchingParts = {}
	local function activateElevator(part: BasePart, params: OverlapParams)
		if elevator:GetAttribute("Activated") == false or not part or touchingParts[part] then
			return
		end

		local component = configuration.Vector or ALLOWED_CFRAME_COMPONENTS[1]
		local faceVector: Vector3 = WORLD_CFRAME_COMPONENTS[component]
			or utility.Property.getPropertySafe(elevator.CFrame, component)
		if not faceVector then
			return
		end

		-- Pro Tip : don't do Vector3.yAxis * math.huge
		local currentMaxForce = Vector3.new(0, configuration.MaxForce, 0)
		if faceVector.X ~= 0 then
			currentMaxForce = Vector3.new(configuration.MaxForce, currentMaxForce.Y, currentMaxForce.Z)
		end
		if faceVector.Z ~= 0 then
			currentMaxForce = Vector3.new(currentMaxForce.X, currentMaxForce.Y, configuration.MaxForce)
		end

		local velocityAttachment = Instance.new("Attachment")
		velocityAttachment.Parent = part

		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "ElevatorVelocity"
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		velocity.Attachment0 = velocityAttachment
		velocity.ForceLimitsEnabled = true
		velocity.MaxAxesForce = currentMaxForce
		velocity.VectorVelocity = faceVector * configuration.Speed
		velocity.Parent = part

		touchingParts[part] = true
		while touchingParts[part] do
			if not elevator.CanTouch or not elevator.CanQuery or elevator:GetAttribute("Activated") == false then
				break
			end
			local zoneParts = Workspace:GetPartsInPart(elevator, params)
			if #zoneParts <= 0 then
				break
			end

			if configuration.ContinuousUpdates then
				faceVector = utility.Property.getPropertySafe(elevator.CFrame, component)
				velocity.VectorVelocity = faceVector * configuration.Speed
			end

			task.wait(UPDATE_INTERVAL)
		end

		touchingParts[part] = nil
		velocity:Destroy()
		velocityAttachment:Destroy()
	end

	--> Main Functionality
	scope:attach(elevator)
	scope:add(elevator.Touched:Connect(function(touchingPart: BasePart)
		if not utility.ClientObjects.evaluateToucher(elevator, touchingPart, touchConfiguration) then
			return
		end

		local part: BasePart
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.CollisionGroup = ""

		local character = localPlayer.Character
		if character and touchingPart:IsDescendantOf(character) then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not (rootPart and rootPart:IsA("BasePart")) then
				return
			end

			part = rootPart
			local hitbox = utility.Character.getHitbox(touchConfiguration.playerHitboxMode or "StaticWholeBody", params)
			if not table.find(hitbox, touchingPart) then
				return
			end
		elseif utility.ClientObjects.isPushbox(touchingPart) then
			part = touchingPart
			params:AddToFilter(touchingPart)
		end

		activateElevator(part, params)
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(elevator, function(rootPart)
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.CollisionGroup = ""
			utility.Character.getHitbox(touchConfiguration.playerHitboxMode or "StaticWholeBody", params)
			activateElevator(rootPart, params)
		end))
	end
end

return Elevator
