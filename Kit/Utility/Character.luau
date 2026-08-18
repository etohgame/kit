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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[=[
    @class Character
    @client
    A table of utility functions for working with the Character that can be used to speed up the process of writing repository scripts for client objects.
]=]
local Character = {}

local Framework = ReplicatedStorage.Framework
local Managers = Framework.Kit.Managers

local localPlayer = Players.LocalPlayer

Character.HitboxModes =
	table.freeze({ "StaticWholeBody", "StaticCenter", "StaticArms", "RootPart", "WholeBody", "Center" })
export type HitboxModes = "StaticWholeBody" | "StaticCenter" | "StaticArms" | "RootPart" | "WholeBody" | "Center" | string

local function _addToListAndFilter(part: BasePart, list: {BasePart}, params: OverlapParams?)
	table.insert(list, part)
	if typeof(params) == "OverlapParams" then
		params:AddToFilter(part)
	end
end

--[=[
	@within Character
	Returns a static hitbox attached to the character based on the provided `mode`.
	See [the documentation on hitbox modes](/docs/misc#hitbox-modes) for more information.
]=]
function Character.getHitbox(mode: HitboxModes, params: OverlapParams?): { BasePart }
	local parts: {BasePart} = {}

	if not localPlayer then
		return {}
	end

	local character = localPlayer.Character
	if not character then
		return parts
	end

	if mode == "RootPart" or mode:find("Static") then
		local hitbox = character:FindFirstChild("_HITBOX") :: typeof(Managers.CharacterManager._HITBOX)?
		if not hitbox then
			return parts
		end

		if mode == "RootPart" then
			_addToListAndFilter(hitbox.RootPart, parts, params)
		elseif mode == "StaticWholeBody" then
			_addToListAndFilter(hitbox.Center, parts, params)
			_addToListAndFilter(hitbox.Arms, parts, params)
		elseif mode == "StaticCenter" then
			_addToListAndFilter(hitbox.Center, parts, params)
		elseif mode == "StaticArms" then
			_addToListAndFilter(hitbox.Arms, parts, params)
		end
	else
		for _, characterPart in character:GetChildren() do
			if not characterPart:IsA("BasePart") or characterPart.Name == "Torso" then
				continue
			end

			if mode == "WholeBody" then
				_addToListAndFilter(characterPart, parts, params)
			elseif (mode :: string) == "Center" and (characterPart.Name ~= "Left Arm" and characterPart.Name ~= "Right Arm") then
				_addToListAndFilter(characterPart, parts, params)
			end
		end
	end

	return parts
end

local CharacterManager = require(Managers.CharacterManager)
local CharacterManager_Types = require(Managers.CharacterManager.TypeDefs)

-- Expose Character Manager methods

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#Damage) for more info.
]=]
function Character.takeDamage(damage: BasePart | number | string)
	CharacterManager:Damage(damage)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#ValidateDamageBrick) for more info.
]=]
function Character.validateDamageBrick(brick: BasePart): (string | number)?
	return CharacterManager:ValidateDamageBrick(brick)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#GetHumanoid) for more info.
]=]
function Character.getHumanoid(): Humanoid?
	return CharacterManager:GetHumanoid(localPlayer)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#ChangeHumanoidProperty) for more info.
]=]
function Character.changeHumanoidProperty(property: string, value: any, tweenInfo: TweenInfo?)
	return CharacterManager:ChangeHumanoidProperty(property, value, tweenInfo)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#StartBoost) for more info.
]=]
function Character.startBoost(boostData: CharacterManager_Types.BoostData)
	return CharacterManager:StartBoost(boostData)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#RemoveBoost) for more info.
]=]
function Character.removeBoost(boostData: CharacterManager_Types.BoostData)
	return CharacterManager:RemoveBoost(boostData)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#GetActiveBoosts) for more info.
]=]
function Character.getActiveBoosts(): { CharacterManager_Types.BoostData }
	return CharacterManager:GetActiveBoosts()
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#GetActiveBoost) for more info.
]=]
function Character.getActiveBoost(boostType: string, boostMode: string?): CharacterManager_Types.BoostData?
	return CharacterManager:GetActiveBoost(boostType, boostMode)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#GetBoostModule) for more info.
]=]
function Character.getBoostModule(boostType: string): CharacterManager_Types.Boost?
	return CharacterManager:GetBoostModule(boostType)
end

--[=[
	@within Character
	
	See [CharacterManager](/api/CharacterManager#RegisterCustomBoost) for more info.
]=]
function Character.registerCustomBoost(boostType: string, boostData: CharacterManager_Types.Boost)
	CharacterManager:RegisterCustomBoost(boostType, boostData)
end

local rootWelds: { [Instance]: WeldConstraint? } = {}
local destroyingConnections: { [Instance]: RBXScriptConnection } = {}
local weldedShoulders: { Motor6D } = {}

--[=[
	@within Character
	
	Makes the character carry the `weldTo` part, welding it to the character
	and displaying a carry animation on the character. The carry animation
	manipulates the character's shoulders directly instead of using an
	AnimationTrack.
	
	If `weldState` is `false`, the character will stop carrying the part and
	the carry animation will stop.
]=]
function Character.carryPart(weldState: boolean, weldTo: BasePart, animationDisabled: boolean)
	local charParts = Character.getCharacter()
	local character = charParts.character
	local humanoid = charParts.humanoid
	if not character or not humanoid then
		return
	end

	if weldState then
		local rootPart = humanoid.RootPart
		if not rootPart or not weldTo then
			return
		end

		if rootWelds[weldTo] then
			Character.carryPart(false, weldTo, animationDisabled)
		end

		weldTo.CFrame = rootPart.CFrame + rootPart.CFrame.UpVector * (weldTo.Size.Y / 2 + 2)
		local rootWeld = Instance.new("WeldConstraint")
		rootWeld.Parent = rootPart
		rootWeld.Part0 = rootPart
		rootWeld.Part1 = weldTo
		rootWelds[weldTo] = rootWeld

		for index, arm in { character:FindFirstChild("Left Arm"), character:FindFirstChild("Right Arm") } do
			if not arm:IsA("BasePart") then
				continue
			end
			local shoulder = character:FindFirstChild(`{arm.Name:split(" ")[1]} Shoulder`, true)
			if not shoulder or not shoulder:IsA("Motor6D") then
				continue
			end
			if animationDisabled then
				continue
			end

			table.insert(weldedShoulders, shoulder)
			local armWeld = Instance.new("WeldConstraint")
			armWeld.Parent = rootWeld

			shoulder.Enabled = false
			arm.CFrame = weldTo.CFrame - weldTo.CFrame.UpVector + (weldTo.CFrame.RightVector * (index - 1.5) * 2.95)
			arm.CFrame *= CFrame.Angles(math.pi, 0, 0)
			armWeld.Part0 = arm
			armWeld.Part1 = weldTo
		end

		destroyingConnections[weldTo] = weldTo.Destroying:Once(function()
			for _, shoulder in weldedShoulders do
				shoulder.Enabled = true
			end

			local humanoid = Character.getHumanoid()
			if humanoid and humanoid.PlatformStand then
				humanoid.PlatformStand = false
			end
		end)
	else
		local weld = rootWelds[weldTo]
		local destroyingConnection = destroyingConnections[weldTo]
		if weld then
			weld:Destroy()
			rootWelds[weldTo] = nil
		end
		if destroyingConnection then
			destroyingConnection:Disconnect()
			destroyingConnections[weldTo] = nil
		end
		if #rootWelds <= 0 then
			for _, shoulder in weldedShoulders do
				shoulder.Enabled = true
			end
		end
		table.clear(weldedShoulders)
	end
end

local characterParts: {character: Model?, primaryPart: BasePart?, humanoid: Humanoid?, rootPart: BasePart?} = {}
local function getParts(character: Model)
	task.defer(function()
		local humanoid = character:WaitForChild("Humanoid")
		characterParts.character = character
		characterParts.primaryPart = character.PrimaryPart
		if humanoid:IsA("Humanoid") then
			characterParts.humanoid = humanoid
			characterParts.rootPart = humanoid.RootPart
		end
	end)
end

if localPlayer then
	if Players.CharacterAutoLoads then
		getParts(localPlayer.Character or localPlayer.CharacterAdded:Wait())
	end
	localPlayer.CharacterAdded:Connect(getParts)
end

--[=[
    @within Character
    
    Returns a table of character instances, such as:
    - The Character itself
    - The Character's humanoid
    - The Character's RootPart
    - The Character's PrimaryPart
    
    When the character respawns, all of the values will update accordingly.
]=]
function Character.getCharacter()
	if not localPlayer then
		return characterParts
	end
	
	getParts(localPlayer.Character or localPlayer.CharacterAdded:Wait())
	return characterParts
end

return table.freeze(Character)
