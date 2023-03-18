local gComponent = require('component')
local gEvent = require('event')
local gSerialization = require('serialization')
local gModem = gComponent.modem
local Commands = require('enums.commands')

local globalArgv = { ... }
local port = 80

local reactorName = globalArgv[1]
local managerName = globalArgv[2]

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
    local res = gModem.broadcast(port, reactorName)
end

function ParseMsg(msgRaw)
    local msgParsed = gSerialization.unserialize(msgRaw)
    local command = msgParsed.command
    local data = msgParsed.data

    return command, data
end

-------------------
-- Main function --
-------------------

local globalCondition = true

ValidateArgs(globalArgv)

Register()

while globalCondition do
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull("modem_message")

    -- Parse message
    local command, data = ParseMsg(msgRaw)

    if (command == Commands.RegisterCallback) then
        
    end
end



-- if (callbackRegister == true) then
--     print('Successfully registered to "' .. managerName .. '" on port: ' .. port .. '\nReactor name: ' .. reactorName)
-- else
--     print('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
-- end