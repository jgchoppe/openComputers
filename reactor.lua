local gComponent = require('component')
local gEvent = require('event')
local gComputer = require('computer')
local gTerm = require("term")
local gGpu = gComponent.gpu
local gModem = gComponent.modem
local json = require('serialization')
local Commands = require('enums.commands')

local globalArgv = { ... }
local port = 80
local timeoutTime = 10 -- in seconds

-- Reactor
local reactorName = globalArgv[1]

-- Manager
local managerName = globalArgv[2]
local managerAdress = nil


--------------------
--      Init      --
--------------------

-- Print helper message
function PrintHelp()
    print('todo: do the helper')
end

-- Validate args and check for help command
function ValidateArgs(args)
    if (args[1] == nil or args[2] == nil) or (string.upper(args[1]) == "-h") then
        PrintHelp()
        os.exit()
    end

    if (args[3] ~= nil) then
        port = args[3] + 0
    end

    return true
end

function Register()
    local params = {
        command = Commands.Register,
        data = {
            type = "reactor",
            machineAddress = gComputer.address(),
            machineName = reactorName,
            managerName = managerName
        }
    }
    local res = gModem.broadcast(port, json.serialize(params))
    if (res == true) then
        print("Trying to register...")
    end
end


--------------------
--      Utils     --
--------------------


function ErrorMessage(msg)
    gGpu.setForeground(0xff0000)
    print('ERROR: '.. msg)
    gGpu.setForeground(0x000000)
end



--------------------
-- Loop Functions --
--------------------

function ParseMsg(msgRaw)
    if (msgRaw == nil) then
        return nil
    end
    local msgParsed = json.unserialize(msgRaw)
    local command = msgParsed.command
    local data = msgParsed.data

    return command, data
end

function RegisterCallback(data)
    if (data.success == true) then
        print('Successfully registered to "' .. managerName .. '" on port: ' .. port .. '\nReactor name: ' .. reactorName)
        if (data.managerAdress ~= nil) then
            managerAdress = data.managerAdress
        end
        return true
    else
        ErrorMessage('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
    end
    return false
end


--------------------
--      Main      --
--------------------

local globalCondition = true
local callbackRegister = false

ValidateArgs(globalArgv)


gTerm.clear()


Register()

function CheckRegisterCallback()
    ErrorMessage('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
    if (callbackRegister == false) then
        globalCondition = false
    end
end

while globalCondition do
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull(timeoutTime, "modem_message")

    -- Parse message
    local command, data = ParseMsg(msgRaw)

    if (command == Commands.RegisterCallback) then
        callbackRegister = RegisterCallback(data)
    end

    CheckRegisterCallback()
end

os.exit()

