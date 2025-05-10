local fs = require("@lune/fs")
local remodel = require("./remodel")
-- i used the remodel port here for convenience

local TMP_DIR = "mirror"
local PLACE_DIR = "place.rbxl"
local PLACE = 122944339391800 -- place is private as of right now CHANGE later

if fs.isDir(TMP_DIR) then
	fs.removeDir(TMP_DIR)
end
fs.writeDir(TMP_DIR)

local place
if fs.isFile(PLACE_DIR) then
	-- load from placefile
	place = remodel.readPlaceFile(PLACE_DIR)
else
	-- load from roblox
	place = remodel.readPlaceAsset(PLACE)
end

local ReplicatedStorage = place:GetService("ReplicatedStorage")
local Framework = ReplicatedStorage:FindFirstChild("Framework")
local Kit = Framework:FindFirstChild("Kit")

-- extract all module scripts (excluding repository scripts and tableutil)
local function extractModule(module: Instance)
	if module:IsA("ModuleScript") and module.Name ~= "table-util" then
		fs.writeFile(`{TMP_DIR}/{module:GetFullName():gsub(Framework:GetFullName(), ""):sub(2)}.luau`, module.Source)
	end
end

for _, dir in Kit:GetChildren() do
	if dir.Name == "Repository" then
		continue
	end

	extractModule(dir)
	for _, module in dir:GetDescendants() do
		extractModule(module)
	end
end
