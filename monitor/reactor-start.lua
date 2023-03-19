local json = require('serialization')
local gComponent = require('component')
local gEvent = require('event')
local gModem = gComponent.modem
local Commands = require('enums.commands')
local globalArgv = { ... }

local timeoutTime = 4

local globalCondition = true
local callbackStatus = false

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

function QueryStart()
    local params = json.serialize({
        command = Commands.CLIReactorStart,
        data = {
            machineAddress = gModem.address,
            name = globalArgv[1]
        }
    })
end

QueryStart()

os.exit()
