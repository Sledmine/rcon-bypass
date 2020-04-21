------------------------------------------------------------------------------
-- Rcon Bypass for SAPP
-- Author: Sledmine
-- Version: 1.0
-- Interceptor for specific rcon commands
------------------------------------------------------------------------------

local inspect = require "inspect"

api_version = "1.12.0.0"

-- Current rcon in the server
local serverRcon

-- Accepted rcon passwords
local acceptedRcons = {}
 
-- Commands to intercept
local commandsList = {}

-- Variables used to store patches address
local rcon_password_address
local rcon_command_failed_message_address

-- Internal functions
local function split(divider, string)
    if (divider == nil or divider == '') then return 1 end
    local position, array = 0, {}
    for st, sp in function() return string.find(string, divider, position, true) end do
        table.insert(array, string.sub(string, position, st-1))
        position = sp + 1
    end
    table.insert(array, string.sub(string, position))
    return array
end

local function arrayHas(array, value)
	value = string.gsub(value, "'", "")
	for k,v in pairs(array) do
		local wildcard = split(v, value)[1]
		if (v == value or wildcard == "") then
			return true
		end
	end
	return false
end

-- Public external functions
function submitRcon(rcon)
	if (not arrayHas(acceptedRcons, rcon)) then
		cprint("Adding new accepted rcon: " .. rcon)
		acceptedRcons[#acceptedRcons + 1] = rcon
		return true
	end
	return false
end

function submitCommand(command)
	if (not arrayHas(commandsList, command)) then
		cprint("Adding new intecepted command: " .. command)
		commandsList[#commandsList + 1] = command
		return true
	end
	return false
end

-- Internal logic functions
local function isCommandByPasseable(command)
	if (arrayHas(commandsList, command)) then
		return true
	end
	return false
end

local function isRconByPasseable(rcon)
	if (arrayHas(acceptedRcons, rcon)) then
		return true
	end
	return false
end

function OnScriptLoad()
	-- Get rcon patches address
	rcon_password_address = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
	rcon_command_failed_message_address = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
	cprint("Rcon password address: " .. string.format("%x", rcon_password_address))
	cprint("Rcon failed message patch address: " .. string.format("%x", rcon_command_failed_message_address))

	if (rcon_command_failed_message_address and rcon_password_address) then
		-- Remove "rcon command failure" message to the player
        safe_write(true)
        write_byte(rcon_command_failed_message_address, 0)
		safe_write(false)
		
		-- Read current rcon in the server
		serverRcon = read_string(rcon_password_address)
		if (serverRcon) then
			cprint("Server rcon password is: '" .. tostring(serverRcon) .. "'")
			register_callback(cb['EVENT_COMMAND'], "onRcon")
		else
			cprint("ERROR!!!! At getting server rcon, please set and enable rcon on the server.")
		end
	else
		cprint("There was a problem obtaining rcon patches, please be sure you are using the correct SAPP version.")
    end
end

function onRcon(playerIndex, command, environment, interceptedRcon)
	if (environment == 1) then
		if (interceptedRcon == serverRcon) then
			return true
		elseif (isRconByPasseable(interceptedRcon)) then
			cprint("Intercepted rcon: " .. interceptedRcon)
			if (isCommandByPasseable(command)) then
				cprint("Intercepted command: " .. command)
				cprint("intercepted command size: " .. #command)
				
			else
				cprint("Intercepted command: " .. command .. " is not in the bypasseable commands.")
				say_all(get_var(playerIndex, "$name") .. " is sending illegal commands trough rcon, watch out.")
				--execute_command("sv_kick " .. playerIndex)
			end
			return false
		else
			say_all(get_var(playerIndex, "$name") .. " was kicked by sending wrong rcon password.")
			execute_command("sv_kick " .. playerIndex)
		end
	end
end

function OnScriptUnload()
	if (rcon_command_failed_message_address) then
		-- Restore patch to the original value
        safe_write(true)
        write_byte(rcon_command_failed_message_address, 0x72)
        safe_write(false)
    end
end