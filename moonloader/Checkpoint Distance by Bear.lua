-----------------------------------------------------
-- INFO
-----------------------------------------------------


script_name("Checkpoint Distance")
script_description("The player character's distance from an active checkpoint, in metres,  is displayed with a block of text.")
script_author("Bear")
script_version("1.1.0")
local script_version = "1.1.0"


-----------------------------------------------------
-- HEADERS & CONFIG
-----------------------------------------------------


require "moonloader"
require "sampfuncs"

local sampev = require "lib.samp.events"
local inicfg = require "inicfg"

local config_dir_path = getWorkingDirectory() .. "\\config\\"
if not doesDirectoryExist(config_dir_path) then createDirectory(config_dir_path) end

local config_file_path = config_dir_path .. "Checkpoint Distance by Bear.ini"

config_dir_path = nil

local config_table

if doesFileExist(config_file_path) then
	config_table = inicfg.load(nil, config_file_path)
else
	local new_config = io.open(config_file_path, "w")
	new_config:close()
	new_config = nil
	
	config_table = {
		DisplayOptions = {
			y_offset = 430,
			size = 1,
			x_offset = 86,
			isCPDOff = false,
			style = 1
		}
	}

	if not inicfg.save(config_table, config_file_path) then
		sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}Config file creation failed - contact the developer for help.", -1)
	end
end


-----------------------------------------------------
-- GLOBAL VARIABLES
-----------------------------------------------------


-- Indicates if a checkpoint doesn't exist
local isACheckpointActive = false

-- Player-controlled display switch (/cpd), connected to the .ini
local isCPDOff = config_table.DisplayOptions.isCPDOff

-- Toggle for recreating the textdraw if settings are changed using /cpdadjust
local isRedrawNeeded = false

-- Checkpoint position coordinates
local cp_posX, cp_posY, cp_posZ = 0

-- Checkpoint radius
local cp_rad = 0


-----------------------------------------------------
-- LOCALLY DECLARED FUNCTIONS
-----------------------------------------------------


local function fetchTextdrawString()
	-- Get player coordinates in integers
	local char_posX, char_posY, char_posZ = getCharCoordinates(PLAYER_PED)
	char_posX, char_posY, char_posZ = math.floor(0.5 + char_posX), math.floor(0.5 + char_posY), math.floor(0.5 + char_posZ)
	
	-- Compute distance b/w player & checkpoint; merge it with a title
	local str = "D:\t" .. math.max(0, math.floor(0.5 + getDistanceBetweenCoords3d(cp_posX, cp_posY, cp_posZ, char_posX, char_posY, char_posZ)) - cp_rad)
	
	-- Comma-format the distance value
	if string.len(str) > 6 then
		for i = string.len(str) - 3, 4, -3 do
			str = string.sub(str, 1, i) .. "," .. string.sub(str, i+1)
		end
	end
	
	return str
end

local function createTextdrawWithGivenString(str)
	sampTextdrawCreate(579, str, config_table.DisplayOptions.x_offset, config_table.DisplayOptions.y_offset)
	sampTextdrawSetLetterSizeAndColor(579, 0.25 * math.pow(config_table.DisplayOptions.size, 0.5), math.pow(config_table.DisplayOptions.size, 0.5), 0xFFFFFFFF)
	sampTextdrawSetStyle(579, config_table.DisplayOptions.style)
	sampTextdrawSetAlign(579, 2)
	sampTextdrawSetOutlineColor(579, 1, 0xFF000000)
end

function main()	
	repeat wait(50) until isSampAvailable()
	sampAddChatMessage("--- {AAAAAA}Checkpoint Distance {FFFFFF}by Bear | Use {AAAAAA}/cpdhelp", -1)
	
	sampRegisterChatCommand("cpd", cmd_cpd)
	sampRegisterChatCommand("cpdpos", cmd_cpdpos)
	sampRegisterChatCommand("cpdsize", cmd_cpdsize)
	sampRegisterChatCommand("cpdstyle", cmd_cpdstyle)
	sampRegisterChatCommand("cpdhelp", cmd_cpdhelp)
	
	-- Inactivity loop
	::start::
	repeat wait(0) until isACheckpointActive and not isCPDOff
	
	-- Creating the textdraw string
	textdrawString = fetchTextdrawString()
	
	-- Creating the textdraw
	::draw::
	createTextdrawWithGivenString(textdrawString)
	
	while isACheckpointActive do
		-- Recreating the textdraw string
		textdrawString = fetchTextdrawString()
		
		-- Updating the textdraw string
		sampTextdrawSetString(579, textdrawString)
		
		wait(0)
		if isCPDOff then break end
		if isRedrawNeeded then
			isRedrawNeeded = false
			goto draw
		end
	end
	
	-- Deleting the textdraw
	sampTextdrawDelete(579)
	goto start
end


-----------------------------------------------------
-- API-SPECIFIC FUNCTIONS
-----------------------------------------------------


function sampev.onSetCheckpoint(position, rad)
	-- Get checkpoint coordinates in integers
	cp_posX, cp_posY, cp_posZ = math.floor(0.5 + position["x"]), math.floor(0.5 + position["y"]), math.floor(0.5 + position["z"])
	
	-- Get checkpoint radius
	cp_rad = rad
	
	isACheckpointActive = true
end

function sampev.onDisableCheckpoint()
	isACheckpointActive = false
end


-----------------------------------------------------
-- COMMAND-SPECIFIC FUNCTIONS
-----------------------------------------------------


function cmd_cpd()
	isCPDOff = config_table.DisplayOptions.isCPDOff
	
	if not isCPDOff then
		isCPDOff, config_table.DisplayOptions.isCPDOff = true, true
		if inicfg.save(config_table, config_file_path) then
			sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}Off", -1)
		else
			sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}CPD toggle in config failed - contact the developer for help.", -1)
		end
	else
		isCPDOff, config_table.DisplayOptions.isCPDOff = false, false
		if inicfg.save(config_table, config_file_path) then
			sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}On", -1)
		else
			sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}CPD toggle in config failed - contact the developer for help.", -1)
		end
	end
end

function cmd_cpdpos(args)
	if #args == 0 or not string.find(args, "[^%s]") then
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdpos (horizontal) (vertical) | {AAAAAA}Default: {FFFFFF}/cpdpos 86 430 (Use 72 430 for widescreen-fixed builds.)", -1)
		sampAddChatMessage(" ", -1)
	elseif string.find(args, "%s*%d+%s+%d+%s*") == 1 then
		config_table.DisplayOptions.x_offset = tonumber(string.match(args, "%d+"))
		config_table.DisplayOptions.y_offset = tonumber(string.match(string.match(args, "%d%s+%d+"), "%d+", 3))
		if inicfg.save(config_table, config_file_path) then
			isRedrawNeeded = true
			sampAddChatMessage("--- {AAAAAA}Updated Position: {FFFFFF} " .. config_table.DisplayOptions.x_offset .. ", " .. config_table.DisplayOptions.y_offset, -1)
		else
			sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}CPD pos. adjustment in config failed - contact the developer for help.", -1)
		end
	else
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdpos (horizontal) (vertical) | {AAAAAA}Default: {FFFFFF}/cpdpos 86 430 (Use 72 430 for widescreen-fixed builds.)", -1)
		sampAddChatMessage(" ", -1)
	end
end

function cmd_cpdsize(args)
	if #args == 0 or not string.find(args, "[^%s]") then
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdsize (1-10) | {AAAAAA}Default: {FFFFFF}/cpdsize 1", -1)
		sampAddChatMessage(" ", -1)
	elseif string.find(args, "%s*%d+%s*") == 1 then
		num = tonumber(string.match(args, "%d+"))
		if num > 0 and num < 11 then
			config_table.DisplayOptions.size = num
			if inicfg.save(config_table, config_file_path) then
				isRedrawNeeded = true
				sampAddChatMessage("--- {AAAAAA}Updated Size: {FFFFFF} " .. config_table.DisplayOptions.size, -1)
			else
				sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}CPD size adjustment in config failed - contact the developer for help.", -1)
			end
		else
			sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {AAAAAA}Size Range: {FFFFFF}1-10", -1)
		end
	else
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdsize (1-10) | {AAAAAA}Default: {FFFFFF}/cpdsize 1", -1)
		sampAddChatMessage(" ", -1)
	end
end

function cmd_cpdstyle(args)
	if #args == 0 or not string.find(args, "[^%s]") then
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdstyle (0-2) | {AAAAAA}Default: {FFFFFF}/cpdstyle 1", -1)
		sampAddChatMessage(" ", -1)
	elseif string.find(args, "%s*%d+%s*") == 1 then
		num = tonumber(string.match(args, "%d+"))
		if num > -1 and num < 3 then
			config_table.DisplayOptions.style = num
			if inicfg.save(config_table, config_file_path) then
				isRedrawNeeded = true
				sampAddChatMessage("--- {AAAAAA}Updated Style: {FFFFFF} " .. config_table.DisplayOptions.style, -1)
			else
				sampAddChatMessage("--- {AAAAAA}Checkpoint Distance: {FFFFFF}CPD style adjustment in config failed - contact the developer for help.", -1)
			end
		else
			sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {AAAAAA}Style Range: {FFFFFF}0-2", -1)
		end
	else
		sampAddChatMessage(" ", -1)
		sampAddChatMessage("--- {FF6666}Invalid Entry {FFFFFF}| {AAAAAA}Usage:", -1)
		sampAddChatMessage("/cpdstyle (0-2) | {AAAAAA}Default: {FFFFFF}/cpdstyle 1", -1)
	sampAddChatMessage(" ", -1)
	end
end

function cmd_cpdhelp()
	sampAddChatMessage("------ {AAAAAA}Checkpoint Distance by Bear - v" .. script_version .. " {FFFFFF}------", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("{AAAAAA}/cpd {FFFFFF}- Toggle the Checkpoint Distance Display", -1)
	sampAddChatMessage("{AAAAAA}/cpdpos (horizontal) (vertical) {FFFFFF}- Adjust Text Position, Offset From Top-Left", -1)
	sampAddChatMessage("{AAAAAA}/cpdsize (1-10) {FFFFFF}- Adjust Text Size", -1)
	sampAddChatMessage("{AAAAAA}/cpdstyle (0-2) {FFFFFF}- Adjust Text Font Style", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("{AAAAAA}Developer: {FFFFFF}Bear (Swapnil#9308)", -1)
	sampAddChatMessage(" ", -1)
	sampAddChatMessage("------------", -1)
end