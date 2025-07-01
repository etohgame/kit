local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local remodel = require("./remodel")
-- i used the remodel port here for convenience

local CFrame = (roblox :: any).CFrame :: CFrame
local Enum = (roblox :: any).Enum :: Enum

local PLACE_DIR = "build.rbxl"
local PLACE = 122944339391800
-- place is private (this is our development environment!)

place = remodel.readPlaceAsset(PLACE)

local ServerStorage = place:GetService("ServerStorage")
local ReplicatedStorage = place:GetService("ReplicatedStorage")
local Kit = ReplicatedStorage.Framework.Kit
local WARNING_MESSAGES = luau.load(ServerStorage.Build.warnings.Source)()
ServerStorage:ClearAllChildren()

--> Remove excess objects from workspace
local instanceWhitelist = { "Misc", "TowerKit", "Camera", "Terrain", "READ ME" }
for _, object in place:GetService("Workspace"):GetChildren() do
	if not table.find(instanceWhitelist, object.Name) then
		print("Removing", object.Name)
		object:Destroy()
	end
end

--> Get Version Numbers
local versionMap = {}
local function traverseFolders(folder: Instance, startingPath: string?)
	local rootPath = startingPath or folder:GetFullName()
	for _, instance in folder:GetChildren() do
		if instance:IsA("ModuleScript") then
			local path = instance:GetFullName():gsub(rootPath, ""):gsub("%.", "/"):sub(2)
			local tag = "CO_" .. path
			local versionTag = instance.Source:match("@version (.-)%s")
			local versionString = "v" .. versionTag:match("-(.+)")
			versionMap[tag] = versionString
		elseif instance:IsA("Folder") then
			traverseFolders(instance, rootPath)
		end
	end
end

traverseFolders(Kit.Repository)

--> Fix Message Keys
for key, value in WARNING_MESSAGES do
	WARNING_MESSAGES[key] = nil
	WARNING_MESSAGES["--@" .. key:gsub("%-", "%%-")] = `--[[\n{value}\n]]`
end

for _, instance in place:GetDescendants() do
	--> Add Version Tags
	for tag, version in versionMap do
		if instance:HasTag(tag) then
			instance:AddTag(version)
		end
	end

	--> Add Warning messages
	if instance:IsA("ModuleScript") or instance:IsA("BaseScript") then
		local finalSource = instance.Source
		for warningKey, warningMessage in WARNING_MESSAGES do
			finalSource = finalSource:gsub(warningKey, warningMessage)
		end

		if instance.Source ~= finalSource then
			instance.Source = finalSource
		end
	end
end

--> Reset Camera
local camera = place:GetService("Workspace").Camera
camera.CFrame = CFrame.new(0, 40, 200) * CFrame.Angles(0, 0, 0)
camera.Focus = CFrame.new(0, 0, 0)
camera.CameraType = Enum.CameraType.Fixed

--> Save
fs.writeFile(PLACE_DIR, roblox.serializePlace(place))
