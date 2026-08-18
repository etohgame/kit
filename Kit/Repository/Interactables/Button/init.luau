--!strict
--!optimize 2
--@version button-6.1.3
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

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local _T = require(ReplicatedStorage.Framework.ClientTypes)
local _TDefs = require(script.TypeDefs)
local SetupSequencerSupport = require(script.SequencerSupport)

local ACTIVE_KEY = "ButtonActive"
local PLATFORM_TAG = "ButtonActivated"
local CACHE_KEY = "button_cache"
local COMMUNICATOR = {
	KEY = "ButtonEvent",
	UPDATE_BUTTONS = "update-button-platforms",
	SET_PRESSED = "set-pressed",
	AWAIT_CACHE = "await-cache",
}

-- every 64 button platforms activated will wait a frame to prevent *some* lag
local PART_BUFFER = 64
local UPDATE_INTERVAL = 1 / 60
local TWEEN_TRANSPARENCY_PROPERTIES: { [string]: string } = {
	-- things that can have their transparency tweened
	Decal = "Transparency",
	Texture = "Transparency",
	SelectionBox = "Transparency",
	SelectionSphere = "Transparency",
	Frame = "BackgroundTransparency",
	CanvasGroup = "GroupTransparency",
	TextLabel = "TextTransparency",
	ImageLabel = "ImageTransparency",
}
local SET_PROPERTIES_ENABLED = {
	-- these will just have their enabled property change instead
	"Beam",
	"ParticleEmitter",
	"Fire",
	"Sparkles",
	"Smoke",
	"Trail",
	"UIStroke",
	"UIGradient",
	-- the following are also toggled in 6.1.2 onwards but are added
	-- manually due to compatibility:
	-- Light, Highlight
}
local SET_PROPERTIES_ENABLED_OPTIONAL: {string} = {
	-- anything in here is manually added to the table for compatibility
}

local TAGS = {
	FullHide = false,
	Invert = false,
	IgnoreAll = false,
	IgnoreTransparency = false,
	IgnoreEnabled = false,
	IgnoreCanCollide = false,
	Invisible = false,
	IgnoreInitialActivate = false,
	UseAltTransparencyLayer = false,
}

local Button = {
	CanQueue = true,
	RunOnStart = false,

	Communicator = COMMUNICATOR,
}

local BUTTON_CONFIG_TEMPLATE = {
	Timer = 0,
	TimerDecimalPlaces = 1,
	TimerText = "{T}",
	PressOffset = CFrame.new(Vector3.yAxis * 0.75),
	PressedMaterial = Enum.Material.Neon,
	HideGUI = false,

	PadMode = false,
	PadDistance = 5,
}

type ConfigTemplate = typeof(BUTTON_CONFIG_TEMPLATE)
type Button = _TDefs.Button<ConfigTemplate>
type ButtonCache = _TDefs.ButtonCache<typeof(TAGS), ConfigTemplate>

local function handleButtonCache(rootScope: _T.Scope, utility: _T.Utility): ButtonCache
	local cache: ButtonCache = { ButtonActivatedPlatforms = {}, Buttons = {} }
	local buttonEvent = rootScope:getCommunicator("event", COMMUNICATOR.KEY)
	local buttonRequest = rootScope:getCommunicator("request", COMMUNICATOR.KEY)

	--> Button Functionality
	local propertyUtil = utility.Property
	local functionUtil = utility.Functions
	local clientObjectUtil = utility.ClientObjects

	local tween = functionUtil.tween
	local roundColor = functionUtil.roundColor
	local setPropertySafe = propertyUtil.setPropertySafe
	local setInstanceActive = clientObjectUtil.setInstanceActive

	local function hasTimer(currentButton: Button)
		return currentButton.Configuration.Timer > 0
	end
	local function getTransparency(platform: Instance, isActivated: boolean)
		local enabledTransparency = propertyUtil.assureAttribute(platform, "SetTransparency", 0)
		local disabledTransparency = propertyUtil.assureAttribute(
			platform,
			"SetInactiveTransparency", 
			if platform:HasTag("FullHide") then 1 else 0.6
		)
		return if isActivated then enabledTransparency else disabledTransparency
	end

	local function activatePlatform(platform: BasePart, isPressed: boolean, targetButton: Button?): boolean
		local currentColor = roundColor(propertyUtil.assureAttribute(platform, "ColorOverride", platform.Color))
		if targetButton and currentColor ~= targetButton.Color then
			return false
		end

		local tags = cache.ButtonActivatedPlatforms[platform]
		if not tags then
			return false
		end

		local isActivated = isPressed
		if tags.Invert then
			isActivated = not isActivated
		end

		setInstanceActive(rootScope, platform, ACTIVE_KEY, isActivated)

		local tweenTime = propertyUtil.assureAttribute(platform, "TweenTime", 0.3)

		for _, descendant in platform:GetDescendants() do
			if descendant:HasTag("IgnoreAll") then
				continue
			end

			for objectType, property in TWEEN_TRANSPARENCY_PROPERTIES do
				if descendant:IsA(objectType) and not descendant:HasTag("IgnoreTransparency") then
					tween(descendant, tweenTime, { [property] = getTransparency(descendant, isActivated) })
				end
			end

			for _, objectType in SET_PROPERTIES_ENABLED do
				if descendant:IsA(objectType) and not descendant:HasTag("IgnoreEnabled") then
					setPropertySafe(descendant, "Enabled", isActivated)
				end
			end

			for _, objectType in SET_PROPERTIES_ENABLED_OPTIONAL do
				if descendant:IsA(objectType) and descendant:HasTag("ToggleEnabled") then
					setPropertySafe(descendant, "Enabled", isActivated)
				end
			end
		end

		local ignoreAll = tags.IgnoreAll
		if not (tags.IgnoreCanCollide or ignoreAll) then
			platform.CanCollide = isActivated
		end
		if not (tags.IgnoreTransparency or tags.Invisible or ignoreAll) then
			local key = if tags.UseAltTransparencyLayer then "LocalTransparencyModifier" else "Transparency"
			tween(platform, tweenTime, { [key] = getTransparency(platform, isActivated) })
		end

		return true
	end

	--> Platform Caching
	local clientObjects = rootScope.clientObjects
	local tempContainer = rootScope.shared.TempContainer
	local function tagFilter(instance: Instance)
		return instance:IsA("BasePart")
			and (instance:IsDescendantOf(clientObjects) or instance:IsDescendantOf(tempContainer))
	end
	local function handleNewPlatform(platform: BasePart)
		local this = {} :: typeof(TAGS)
		cache.ButtonActivatedPlatforms[platform] = this
		for key in TAGS do -- we love broken type inference
			this[key] = platform:HasTag(key)
		end
		if not this.IgnoreInitialActivate then
			task.defer(activatePlatform, platform, false, nil)
		end
	end

	for _, platform in CollectionService:GetTagged(PLATFORM_TAG) do
		if not tagFilter(platform) then
			continue
		end
		handleNewPlatform(platform :: BasePart)
	end
	rootScope:add(CollectionService:GetInstanceAddedSignal(PLATFORM_TAG):Connect(function(instance)
		if not tagFilter(instance) or not instance:IsA("BasePart") then
			return
		end
		handleNewPlatform(instance)
	end))
	rootScope:add(CollectionService:GetInstanceRemovedSignal(PLATFORM_TAG):Connect(function(instance)
		if not cache then
			return
		end
		cache.ButtonActivatedPlatforms[instance] = nil
	end))

	for key in pairs(TAGS) do -- we love broken type inference x2
		rootScope:add(CollectionService:GetInstanceAddedSignal(key):Connect(function(instance)
			local platform = cache and cache.ButtonActivatedPlatforms[instance]
			if platform then
				platform[key] = true
			end
		end))
		rootScope:add(CollectionService:GetInstanceRemovedSignal(key):Connect(function(instance)
			local platform = cache and cache.ButtonActivatedPlatforms[instance]
			if platform then
				platform[key] = false
			end
		end))
	end

	--> Listen to events
	buttonEvent:listen(function(type: string, ...)
		if type == COMMUNICATOR.UPDATE_BUTTONS then
			local targetButton: Button, isPressed: boolean = ...
			if
				typeof(isPressed) ~= "boolean"
				or not (typeof(targetButton) == "table" and typeof(targetButton.ID) == "string")
			then
				return
			end

			local valuesToChange: { BoolValue } = {}
			for _, currentButton in cache.Buttons do
				if
					not currentButton
					or currentButton.ID == targetButton.ID
					or currentButton.Color ~= targetButton.Color
					or targetButton.Configuration.PadMode
				then
					continue
				end

				local timerInvolved = hasTimer(currentButton)
				if not timerInvolved then
					table.insert(valuesToChange, currentButton.Pressed)
				end
			end

			for _, value in valuesToChange do
				value.Value = isPressed
			end

			local partsActivated = 0
			for platform in cache.ButtonActivatedPlatforms do
				local didActivate = activatePlatform(platform, isPressed, targetButton)

				if didActivate then
					partsActivated += 1
					if (partsActivated % PART_BUFFER) == 0 then
						task.wait()
					end
				end
			end
		end
	end)

	buttonRequest:listen(function(type: string, ...)
		if type == COMMUNICATOR.AWAIT_CACHE then
			return cache
		end
	end)

	--> Sequencer Setup
	SetupSequencerSupport(rootScope, utility, cache)

	--> Cleanup
	rootScope:add(function()
		rootScope.shared[CACHE_KEY] = nil
		table.clear(cache.Buttons)
		table.clear(cache.ButtonActivatedPlatforms)
		cache = nil :: any
		rootScope = nil :: any
	end)

	return cache
end

function Button.Run(scope: _T.Scope, utility: _T.Utility)
	local buttonConfig = scope.instance
	if not buttonConfig or not buttonConfig.Parent then
		return
	end

	local buttonParent = buttonConfig.Parent
	local buttonPart = buttonParent:FindFirstChild("ButtonPart")
	if not buttonPart or not buttonPart:IsA("BasePart") then
		return
	end

	local clientObjectUtil = utility.ClientObjects

	-- add some stuff if v6.1.2 or later
	-- this is done for oompatibility reasons
	local coVersion = clientObjectUtil.getCOVersion(buttonConfig)
	if clientObjectUtil.isVersionOrHigher(coVersion, "v6.1.2") then
		table.insert(SET_PROPERTIES_ENABLED, "Light")
		table.insert(SET_PROPERTIES_ENABLED, "Highlight")
	end
	if clientObjectUtil.isVersionOrHigher(coVersion, "v6.1.3") then
		table.insert(SET_PROPERTIES_ENABLED_OPTIONAL, "Constraint")
	end

	local cache = utility.Scope.getCached(scope, CACHE_KEY, handleButtonCache)
	-- ^ To get this cache from an external script, please do the following:
	-- `scope:getCommunicator("request", "ButtonEvent"):request("await-cache")`

	local buttonEvent = scope:getCommunicator("event", COMMUNICATOR.KEY)
	scope:attach(buttonParent, true)

	--> Configurations
	local Config = utility.Config
	local configuration = Config.GetConfig(scope, buttonConfig, BUTTON_CONFIG_TEMPLATE):ObserveChanges()
	local touchConfiguration =
		Config.GetConfig(scope, buttonConfig:FindFirstChild("TouchConfiguration"), Config.TOUCH_CONFIG):ObserveChanges()
	local tweenConfiguration =
		Config.GetConfig(scope, buttonConfig:FindFirstChild("TweenConfiguration"), Config.TWEEN_CONFIG):ObserveChanges()

	local thisID = utility.Functions.generateUID()
	local thisButton: Button = {
		Button = buttonPart,
		Configuration = configuration,
		Color = utility.Functions.roundColor(buttonPart.Color),
		Pressed = scope:add(Instance.new("BoolValue")),
		ID = thisID,
		TotalPresses = 0,
		TimerFinished = scope:add(Instance.new("BindableEvent")),
	}
	thisButton.Pressed.Name = "Pressed"
	thisButton.Pressed.Parent = buttonParent
	local timerStart = scope:add(Instance.new("NumberValue"))
	timerStart.Name = "TimerStart"
	timerStart.Parent = buttonParent

	cache.Buttons[buttonPart] = thisButton
	scope:add(function()
		cache.Buttons[buttonPart] = nil
	end)

	local timerLabel = buttonConfig:FindFirstChildWhichIsA("TextLabel") :: TextLabel?

	local function updatePlatforms(pressed: boolean?)
		-- don't deactivate if there's a different button of the same color active
		-- this is to match v5.5 behavior

		if not pressed then
			for _, otherButton in cache.Buttons do
				if
					otherButton
					and otherButton.ID ~= thisID
					and otherButton.Color == thisButton.Color
					and otherButton.Pressed.Value
				then
					return
				end
			end
		end

		buttonEvent:fire(
			COMMUNICATOR.UPDATE_BUTTONS,
			thisButton,
			if pressed ~= nil then pressed else thisButton.Pressed.Value
		)
	end

	local debounce = false
	local originalCFrame = buttonPart.CFrame
	local originalMaterial = buttonPart.Material

	--> Setup PadMode
	local padHitbox
	if configuration.PadMode then
		local distance = configuration.PadDistance
		padHitbox = Instance.new("Part")
		padHitbox.Name = "Hitbox"
		padHitbox.Transparency = 1
		padHitbox.CanCollide = false
		padHitbox.CanTouch = false
		padHitbox.CanQuery = true
		padHitbox.Massless = true
		padHitbox.Anchored = false
		padHitbox.Size = Vector3.new(buttonPart.Size.X + 0.5, math.abs(distance), buttonPart.Size.Z + 0.5)
		padHitbox.CFrame = originalCFrame * CFrame.new(0, (padHitbox.Size.Y * 0.5) + (buttonPart.Size.Y * 0.5) - 1, 0)

		local buttonWeld = Instance.new("WeldConstraint")
		buttonWeld.Part0 = buttonPart
		buttonWeld.Part1 = padHitbox
		buttonWeld.Parent = padHitbox
		padHitbox.Parent = buttonPart
	end

	--> Detect Button updates
	scope:add(thisButton.Pressed:GetPropertyChangedSignal("Value"):Connect(function()
		local isPressed = thisButton.Pressed.Value
		thisButton.TotalPresses += 1
		buttonPart.Material = if isPressed then configuration.PressedMaterial else originalMaterial
		if buttonPart.Anchored then
			utility.Functions.tween(
				buttonPart,
				tweenConfiguration,
				{ CFrame = if isPressed then originalCFrame * configuration.PressOffset else originalCFrame }
			)
		end

		local sound = buttonPart:FindFirstChild("Press")
		if sound and sound:IsA("Sound") and isPressed then
			sound:Play()
		end

		updatePlatforms(isPressed)

		--> Timer functionality
		if configuration.Timer > 0 and isPressed then
			local pressId = thisButton.TotalPresses
			local labels = {} :: { TextLabel }
			local timerScope = scope:inherit()
			timerStart.Value = os.clock()
			local timerFinished = thisButton.TimerFinished
			timerScope:add(function()
				-- in the case that the scope is cleaning up but the timer
				-- hasn't finished
				timerFinished:Fire()
				timerStart.Value = 0
			end)

			if not configuration.HideGUI and timerLabel then
				local screenText = timerScope:add(timerLabel:Clone())
				screenText.Visible = false
				if not screenText:HasTag("UseSpecialColor") then
					local buttonColor = buttonPart.Color
					screenText.TextColor3 = buttonColor
					screenText.TextStrokeColor3 = Color3.new(1 - buttonColor.R, 1 - buttonColor.G, 1 - buttonColor.B)
				end

				local partText = timerScope:add(screenText:Clone())
				local surfaceGui = timerScope:add(Instance.new("SurfaceGui"))
				surfaceGui.Face = Enum.NormalId.Top
				surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				surfaceGui.PixelsPerStud = 50
				surfaceGui.Parent = buttonPart

				screenText.Parent = utility.Gui.getEffectGui().TimerList
				partText.Parent = surfaceGui
				table.insert(labels, screenText)
				table.insert(labels, partText)
				timerScope:attach(screenText, true)
				timerScope:attach(surfaceGui, true)
			end

			local timeAmount = configuration.Timer
			timerScope:add(RunService.Heartbeat:Connect(function()
				if thisButton.TotalPresses ~= pressId then
					timerFinished:Fire()
					return
				end

				local actualTime = timeAmount - (os.clock() - timerStart.Value)
				if actualTime <= 0 then
					timerFinished:Fire()
					return
				end

				local timerText = clientObjectUtil.formatTimerText(
					configuration.TimerText,
					configuration.TimerDecimalPlaces,
					actualTime
				)
				for _, label in labels do
					if label.Text ~= timerText then
						label.Text = timerText
					end

					if not label.Visible then
						label.Visible = true
					end
				end
			end))

			timerFinished.Event:Wait()
			timerScope:cleanup(false, true)
			if thisButton.TotalPresses == pressId then
				thisButton.Pressed.Value = false
			end
		end
	end))

	--> Activation
	local characterInstances = utility.Character.getCharacter()
	local touchingParts: { [BasePart]: boolean } = {}
	local function activateButton(toucher: BasePart)
		if
			debounce
			or touchingParts[toucher]
			or thisButton.Pressed.Value
			or buttonPart:GetAttribute("Activated") == false
		then
			return
		end

		debounce = true
		thisButton.Pressed.Value = true

		if padHitbox then
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.CollisionGroup = ""
			if toucher:IsDescendantOf(characterInstances.character) and characterInstances.rootPart then
				utility.Character.getHitbox(touchConfiguration.playerHitboxMode or "WholeBody", params)
				toucher = characterInstances.rootPart
			else
				params:AddToFilter(toucher)
			end

			touchingParts[toucher] = true
			while touchingParts[toucher] and thisButton.Pressed.Value do
				if
					not buttonPart.CanTouch
					or not buttonPart.CanQuery
					or buttonPart:GetAttribute("Activated") == false
				then
					break
				end
				local zoneParts = Workspace:GetPartsInPart(padHitbox, params)
				if #zoneParts <= 0 then
					break
				end

				task.wait(UPDATE_INTERVAL)
			end

			thisButton.Pressed.Value = false
			touchingParts[toucher] = nil
		end

		task.delay(0.25, function()
			debounce = false
		end)
	end

	scope:add(buttonPart.Touched:Connect(function(toucher: BasePart)
		if not utility.ClientObjects.evaluateToucher(buttonPart, toucher, touchConfiguration) then
			return
		end

		activateButton(toucher)
	end))

	if touchConfiguration.canFlip then
		scope:add(utility.ClientObjects.bindToFlip(buttonPart, activateButton))
	end
end

return Button
