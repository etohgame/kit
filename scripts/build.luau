local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local remodel = require("./remodel")
-- i used the remodel port here for convenience

local CFrame = (roblox :: any).CFrame :: CFrame
local Enum = (roblox :: any).Enum :: Enum

local PLACE_DIR = "build.rbxl"
local PLACE = 122944339391800 -- place is private as of right now CHANGE later

place = remodel.readPlaceAsset(PLACE)

local ServerStorage = place:GetService("ServerStorage")
local WARNING_MESSAGES = luau.load(ServerStorage.Build.warnings.Source)()
ServerStorage:ClearAllChildren()

--> Fix Message Keys
for key, value in WARNING_MESSAGES do
	WARNING_MESSAGES[key] = nil
	WARNING_MESSAGES["--@" .. key:gsub("%-", "%%-")] = `--[[\n{value}\n]]`
end

--> Add Warning messages
for _, currentScript in place:GetDescendants() do
	if not (currentScript:IsA("ModuleScript") or currentScript:IsA("BaseScript")) then
		continue
	end

	local finalSource = currentScript.Source
	for warningKey, warningMessage in WARNING_MESSAGES do
		finalSource = finalSource:gsub(warningKey, warningMessage)
	end

	if currentScript.Source == finalSource then
		continue
	end
	currentScript.Source = finalSource
end

--> Reset Camera
local camera = place:GetService("Workspace").Camera
camera.CFrame = CFrame.new(0, 40, 200) * CFrame.Angles(0, 0, 0)
camera.Focus = CFrame.new(0, 0, 0)
camera.CameraType = Enum.CameraType.Fixed

--> Save
fs.writeFile(PLACE_DIR, roblox.serializePlace(place))
