--!strict
--!optimize 2
--@version vanisher-6.1.2
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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local _T = require(ReplicatedStorage.Framework.ClientTypes)

-- Constants
type VanisherPart = {
	part: BasePart,
	selection: SelectionBox?,
	defaults: { [string]: any },
}

local ALLOWED_VANISH_MODES = { "Fade", "Blink", "Constant", "Shrink" }
local ALLOWED_SHRINK_DIRECTIONS = {
	"Center",
	"Top",
	"Bottom",
	"Front",
	"Back",
	"Left",
	"Right",
}

local ACTIVE_KEY = "VanisherActive"

local SHRINK_DIRECTION_OFFSETS = {
	Center = Vector3.zero,
	Top = Vector3.yAxis,
	Bottom = -Vector3.yAxis,
	Front = -Vector3.zAxis,
	Back = Vector3.zAxis,
	Left = -Vector3.xAxis,
	Right = Vector3.xAxis,
}

local Vanisher = {
	CanQueue = true,
	RunOnStart = false,
}

local VANISHER_CONFIG_TEMPLATE
function Vanisher.Init(utility: _T.Utility)
	local Config = utility.Config
	VANISHER_CONFIG_TEMPLATE = {
		BlinkCount = 3,
		ConstantNoRecovery = false,
		Invert = false,
		OutlineColor = Color3.fromRGB(255, 0, 0),
		RespawnFade = false,
		RespawnTime = 2,
		VanishMode = Config.Type.Some(table.unpack(ALLOWED_VANISH_MODES)),
		ShrinkDirection = Config.Type.Some(table.unpack(ALLOWED_SHRINK_DIRECTIONS)),
		ShrinkToZero = false,
	}
end

local SequencerSupport = require(script.SequencerSupport)
local function handleCache(rootScope: _T.Scope, utility: _T.Utility)
	local cache = {} :: { [Instance]: () -> () }
	SequencerSupport(rootScope, utility, cache)
	return cache
end

function Vanisher.Run(scope: _T.Scope, utility: _T.Utility)
	local vanisherConfig = scope.instance
	if not vanisherConfig or not vanisherConfig.Parent then
		return
	end

	--> Configuration setup
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, vanisherConfig, VANISHER_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, vanisherConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG)
			:ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, vanisherConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG)
			:ObserveChanges()

	local vanisherObject = vanisherConfig.Parent
	local vanisherParts: { VanisherPart } = {}
	local vanisherChildren: { Instance } = if vanisherObject:IsA("BasePart")
		then { vanisherObject }
		else vanisherObject:GetChildren()

	--> Fix a silly issue
	local invertZDirections: boolean
	do
		local coVersion = utility.ClientObjects.getCOVersion(vanisherConfig)
		invertZDirections = not utility.ClientObjects.isVersionOrHigher(coVersion, "v6.1.4")
	end
	---------------

	for _, part in vanisherChildren do
		if part:IsA("BasePart") then
			local selectionBox = part:FindFirstChild("VanisherSelectionBox")
			if selectionBox and not selectionBox:IsA("SelectionBox") then
				continue
			end

			local invisible = part:HasTag("Invisible")
			local ignoreTransparency = part:HasTag("IgnoreTransparency")
			local ignoreCanCollide = part:HasTag("IgnoreCanCollide")

			local defaultCanCollide = if invisible
				then false
				elseif ignoreCanCollide then part.CanCollide
				else not configuration.Invert

			local touchedCanCollide = if invisible
				then false
				elseif ignoreCanCollide then part.CanCollide
				else not defaultCanCollide

			local defaultTransparency = if invisible
				then 1
				elseif ignoreTransparency then part.Transparency
				elseif configuration.Invert then 1
				else part.Transparency

			local touchedTransparency = if ignoreTransparency
				then part.Transparency
				else if configuration.Invert then 0 else 1

			local defaultProperties = {
				DefaultLineThickness = if selectionBox then selectionBox.LineThickness else 0.1,
				DefaultOutlineColor = if selectionBox then selectionBox.Color3 else Color3.new(),
				DefaultCanCollide = defaultCanCollide,
				DefaultTransparency = defaultTransparency,
				TouchedCanCollide = touchedCanCollide,
				TouchedTransparency = touchedTransparency,
				OriginalTransparency = part.Transparency,
			}
			
			local vanisherTable: VanisherPart = {
				part = part,
				selection = selectionBox,
				defaults = defaultProperties,
			}

			table.insert(vanisherParts, vanisherTable)
			part.Transparency = defaultProperties.DefaultTransparency
			part.CanCollide = defaultProperties.DefaultCanCollide
			part:AddTag("IgnoreAll")
			scope:attach(part)
		end
	end

	if #vanisherParts <= 0 then
		return
	end

	local active = false
	local touchingParts: { [BasePart]: boolean } = {}
	local touchTime = 0
	local totalFadeTime = tweenConfiguration.Time
	local cleanupScope = scope:inherit()

	local function updateSelectionBox(color: Color3?, thickness: number?)
		for _, vanisher in vanisherParts do
			local selectionBox = vanisher.selection
			if selectionBox then
				selectionBox.Color3 = color or vanisher.defaults.DefaultOutlineColor
				if thickness then
					selectionBox.LineThickness = thickness
				end
			end
		end
	end

	local function startTween(instance: Instance, properties: { [string]: any })
		return cleanupScope:add(utility.Functions.tween(instance, tweenConfiguration, properties))
	end

	--> Core functionality
	local function respawn(vanisherPart: VanisherPart)
		cleanupScope:cleanup()
		touchingParts = {}
		touchTime = 0

		local vanisher = vanisherPart.part
		vanisher.CanCollide = vanisherPart.defaults.DefaultCanCollide
		vanisher.CanTouch = true
		active = false
		utility.ClientObjects.setInstanceActive(scope, vanisher, ACTIVE_KEY, true)

		if configuration.RespawnFade then
			startTween(vanisher, { Transparency = vanisherPart.defaults.DefaultTransparency })
		else
			vanisher.Transparency = vanisherPart.defaults.DefaultTransparency
		end

		updateSelectionBox(vanisherPart.defaults.DefaultOutlineColor)
	end

	local function vanish(vanisherPart: VanisherPart)
		local vanisher = vanisherPart.part
		active = true
		utility.ClientObjects.setInstanceActive(scope, vanisher, ACTIVE_KEY, false)
		vanisher.CanCollide = vanisherPart.defaults.TouchedCanCollide
		vanisher.CanTouch = false
		vanisher.Transparency = vanisherPart.defaults.TouchedTransparency
		updateSelectionBox(configuration.OutlineColor)
		task.delay(configuration.RespawnTime, respawn, vanisherPart)
	end

	--> Vanish mode implementations
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.CollisionGroup = ""

	local function handleConstantMode(vanisherPart: VanisherPart)
		local vanisher = vanisherPart.part
		local defaults = vanisherPart.defaults

		params.FilterDescendantsInstances = {}
		for part in touchingParts do
			params:AddToFilter(part)
		end

		while true do
			local deltaTime = task.wait(1 / 60)

			local currentParts =
				Workspace:GetPartBoundsInBox(vanisher.CFrame, vanisher.Size + Vector3.one * 0.1, params)
			local currentPartsSet = {}
			for _, part in currentParts do
				currentPartsSet[part] = true
			end

			-- Update touching parts
			for part in touchingParts do
				if not currentPartsSet[part] then
					touchingParts[part] = nil
				end
			end

			-- Update fade time
			if next(currentParts) ~= nil then
				touchTime = math.min(touchTime + deltaTime, totalFadeTime)
			elseif not configuration.ConstantNoRecovery then
				touchTime = math.max(touchTime - (deltaTime * totalFadeTime / configuration.RespawnTime), 0)
			end

			local transparency = defaults.DefaultTransparency
				+ (defaults.TouchedTransparency - defaults.DefaultTransparency) * (touchTime / totalFadeTime)
			for _, otherVanisher in vanisherParts do
				otherVanisher.part.Transparency = transparency
			end

			if touchTime >= totalFadeTime then
				for _, otherVanisher in vanisherParts do
					vanish(otherVanisher)
				end
				break
			end
		end
	end

	local function handleBlinkMode(vanisherPart: VanisherPart)
		local vanisher = vanisherPart.part
		local selectionBox = vanisherPart.selection
		local defaults = vanisherPart.defaults

		local blinkSound = vanisher:FindFirstChild("BlinkSound") or script.DefaultBlinkSound
		blinkSound = blinkSound:Clone()
		blinkSound.Name = "Blinked"
		blinkSound.Parent = vanisher

		for i = 1, configuration.BlinkCount do
			blinkSound:Play()

			if selectionBox then
				selectionBox.LineThickness = defaults.DefaultLineThickness * 3
				startTween(selectionBox, { LineThickness = defaults.DefaultLineThickness }).Completed:Wait()
			else
				startTween(
					vanisher,
					{ Transparency = (defaults.DefaultTransparency + defaults.TouchedTransparency) / 2 }
				).Completed:Wait()
			end
		end

		blinkSound.PlaybackSpeed *= 1.2
		blinkSound:Play()
		task.delay(blinkSound.TimeLength / blinkSound.PlaybackSpeed, function()
			blinkSound:Destroy()
		end)
		vanish(vanisherPart)
	end

	local function handleShrinkMode(vanisherPart: VanisherPart)
		local vanisher = vanisherPart.part
		local shrinkPart = cleanupScope:add(Instance.fromExisting(vanisher))

		vanisher.Transparency = 1
		vanisher.CanCollide = false
		shrinkPart.Transparency = 0
		shrinkPart.CanCollide = true
		shrinkPart.Anchored = true
		shrinkPart.Parent = vanisher

		local direction = SHRINK_DIRECTION_OFFSETS[configuration.ShrinkDirection]
		local startSize = vanisher.Size
		local endSize = Vector3.zero
		local shrinkPartCFrame = vanisher.CFrame
		if configuration.ShrinkDirection ~= "Center" then
			if direction.X ~= 0 then
				endSize = Vector3.new(0, startSize.Y, startSize.Z)
			elseif direction.Y ~= 0 then
				endSize = Vector3.new(startSize.X, 0, startSize.Z)
			elseif direction.Z ~= 0 then
				if invertZDirections then
					direction *= -1
				end
				endSize = Vector3.new(startSize.X, startSize.Y, 0)
			end

			local offset = (-0.5 * direction) * startSize
			shrinkPartCFrame *= CFrame.new(offset)
		end

		if configuration.ShrinkToZero then
			endSize = Vector3.zero
		end

		if configuration.Invert then
			shrinkPart.Size = endSize
			endSize = startSize
		else
			shrinkPart.Size = startSize
		end

		-- To support moving for unanchored objects
		local vanisherConnection = cleanupScope:add(RunService.PreRender:Connect(function()
			shrinkPart.CFrame = shrinkPartCFrame * CFrame.new((shrinkPart.Size * 0.5) * direction)
		end))

		local tween = startTween(shrinkPart, { Size = endSize })
		tween.Completed:Wait()
		shrinkPart.Size -= Vector3.one * 1e-2
		vanish(vanisherPart)
		if configuration.RespawnFade then
			shrinkPart.CanCollide = false
			startTween(shrinkPart, { Transparency = 1 })
		end

		cleanupScope:remove(vanisherConnection)
		cleanupScope:remove(shrinkPart)
	end

	local VANISH_HANDLERS = {
		Constant = function()
			return handleConstantMode
		end,

		Blink = function()
			active = true
			return handleBlinkMode
		end,

		Fade = function()
			active = true
			return function(vanisherPart: VanisherPart)
				startTween(vanisherPart.part, { Transparency = vanisherPart.defaults.TouchedTransparency }).Completed:Wait()
				vanish(vanisherPart)
			end
		end,

		Shrink = function()
			active = true
			return handleShrinkMode
		end,
	}

	updateSelectionBox()

	local function getTransparency(platform: Instance, isActivated: boolean)
		local enabledTransparency = utility.Property.assureAttribute(platform, "SetTransparency", 0)
		local disabledTransparency = if platform:HasTag("FullHide") then 1 else 0.6
		return if isActivated then enabledTransparency else disabledTransparency
	end

	local function onActivatedChanged(vanisherPart: VanisherPart)
		local vanisher = vanisherPart.part
		local defaultProperties = vanisherPart.defaults

		local activated = vanisher:GetAttribute("Activated")
		cleanupScope:cleanup()
		active = false
		touchTime = 0

		if not vanisher:HasTag("ButtonActivated") then
			-- the code below is only for button activated vanishers
			return
		end
		defaultProperties.DefaultCanCollide = activated
		if configuration.Invert then
			-- gross instant flash but cant be bothered to tween rn
			vanisher.CanCollide = false
			defaultProperties.DefaultTransparency = 1
			vanisher.Transparency = 1
		else
			defaultProperties.DefaultTransparency = if activated
				then defaultProperties.OriginalTransparency
				else getTransparency(vanisher, active)
			vanisher.Transparency = defaultProperties.DefaultTransparency
			vanisher.CanCollide = activated
		end

		defaultProperties.TouchedTransparency = 1 - defaultProperties.DefaultTransparency
		vanisher.CanTouch = activated
	end

	for _, vanisherPart in vanisherParts do
		local vanisher = vanisherPart.part
		if vanisher:GetAttribute("Activated") ~= nil then
			onActivatedChanged(vanisherPart)
		end
		scope:add(vanisher:GetAttributeChangedSignal("Activated"):Connect(function()
			onActivatedChanged(vanisherPart)
		end))
	end

	--> Main Functionality
	local function spawnVanisher(vanisherPart: VanisherPart, hitPart: BasePart?)
		local vanisher = vanisherPart.part
		if active or vanisher:GetAttribute("Activated") == false then
			return
		end

		cleanupScope:cleanup()
		local modeHandler = VANISH_HANDLERS[configuration.VanishMode]
		if modeHandler then
			if configuration.VanishMode == "Constant" and hitPart then
				touchingParts[hitPart] = true
				params:AddToFilter(hitPart)
				cleanupScope:spawn(modeHandler(), vanisherPart)
				return
			end

			for i, otherVanisher in vanisherParts do
				cleanupScope:spawn(modeHandler(), otherVanisher)
			end
		end
	end

	local function getWholeBody()
		return utility.Character.getHitbox("StaticWholeBody")
	end

	for _, vanisherPart in vanisherParts do
		local vanisher = vanisherPart.part

		scope:add(vanisher.Touched:Connect(function(hitPart: BasePart)
			if not utility.ClientObjects.evaluateToucher(vanisher, hitPart, touchConfiguration) then
				return
			end

			if hitPart:IsDescendantOf(Players.LocalPlayer.Character) then
				hitPart = getWholeBody()[1]
			end

			spawnVanisher(vanisherPart, hitPart)
		end))

		if touchConfiguration.canFlip then -- RIP @v6.0.1
			scope:add(utility.ClientObjects.bindToFlip(vanisher, function(rootPart)
				spawnVanisher(vanisherPart, getWholeBody()[1])
			end))
		end
	end

	--> Sequencer Cache Support
	local cache = utility.Scope.getCached(scope, scope.scriptPath, handleCache)
	cache[vanisherObject] = function()
		spawnVanisher(vanisherParts[1], getWholeBody()[1])
	end
	scope:add(function()
		cache[vanisherObject] = nil
		cache = nil :: any
	end)
end

return Vanisher
