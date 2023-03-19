local json = require('serialization')
local gComponent = require('component')
local gEvent = require('event')
local gModem = gComponent.modem
local Commands = require('enums.commands')
local globalArgv = { ... }

local port = 80

if (globalArgv[1] == nil) then
    print("reactor-status <REACTOR_NAME>")
    os.exit()
end

-- todo: get manager address
local managerAddress = os.getenv("MAIN_ADDRESS")
if (managerAddress == nil) then
    print('Manager address is null, check env with os.getenv("MAIN_ADDRESS")')
    os.exit()
end

function QueryStop()
    local params = json.serialize({
        command = Commands.CLIReactorStop,
        data = {
            machineAddress = gModem.address,
            name = globalArgv[1]
        }
    })
    gModem.send(managerAddress, port, params)
end

QueryStop()

os.exit()
