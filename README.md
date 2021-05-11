# Rcon Bypass
This is a simple module to provide security and functionality to the rcon system in SAPP, allowing
you to avoid boiler plate, providing an easier way to achieve communication between server and
client using the rcon system.

## How it works?

You can require this module on your code and submit different commands, for admins and for
interception purposes:
```lua
local rcon = require "rcon"

-- Override the rcon callback with the module callback
OnCommand = rcon.OnCommand

-- Provide a commands interceptor function
function rcon.commandInterceptor(playerIndex, command, environment, rconPassword)
    if (command == "reset") then
        -- Do stuff
    end
end

function OnScriptLoad()
    -- Attach rcon modifications to the game
    rcon.attach()

    -- Submit a safe to intecept rcon
    rcon.submitRcon("sled")

    -- Add your public and admin commands
    rcon.submitCommand("fly")
    rcon.submitCommand("taxi")

    rcon.submitAdminCommand("reset")
    rcon.submitAdminCommand("debugmode")
end

-- Do not forget to detach rcon at unloading script or when necessary
function OnScriptUnload()
    rcon.detach()
end
```

# Changelog
See this [markdown](CHANGELOG.md) for changelog details!
