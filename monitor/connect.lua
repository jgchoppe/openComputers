local json = require('serialization')
local gComponent = require('component')
local gEvent = require('event')
local gTerm = require("term")
local gGpu = gComponent.gpu
local gModem = gComponent.modem
local fs = gComponent.filesystem

local Commands = require('enums.commands')

local globalArgv = { ... }
local port = 80

local timeoutTime = 4

local globalCondition = true
local callbackRegister = false



function GetArg(arg, default)
    if arg ~= nil then
        return arg
    else
        return default
    end
end
local managerName = GetArg(globalArgv[1], "main")


function ErrorMessage(msg)
    gGpu.setForeground(0xff0000)
    print('ERROR: '.. msg)
    gGpu.setForeground(0x000000)
end


--------------------
--      Init      --
--------------------

-- Print helper message
function PrintHelp()
    print('todo: do the helper')
end


function Register(firstTime)
    local params = {
        command = Commands.Register,
        data = {
            type = "cli",
            machineAddress = gModem.address,
            machineName = nil,
            managerName = managerName
        }
    }
    local res = gModem.broadcast(port, json.serialize(params))
    if (res == true) and (firstTime == true) then
        print("Trying to register to main Manager...")
    end
end



--------------------
--      Main      --
--------------------
gModem.open(port)

local firstTime = true

-- Main Loop

while globalCondition do
    Register(firstTime)
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull(timeoutTime, "modem_message")

    -- Debug mode below
    -- local _, _, _, _, _, msgRaw = gEvent.pull("modem_message")
    -- callbackRegister = true
    -- Debug mode upper

    -- Handle message
    if (msgRaw ~= nil) then
        local res = json.unserialize(msgRaw)
        if (res.command == Commands.RegisterCallback) then
            if (res.data.success == true) and (res.data.managerAddress ~= nil) then
                os.setenv("MAIN_ADDRESS", res.data.managerAddress)
                print('Successfully connected to main Manager.')
                fs.
                globalCondition = false
                callbackRegister = true
            else
                print('Callback : Failed when registering to main Manager.')
            end
        end
    end

    if (callbackRegister == false) then
        firstTime = false
        print('Retrying...')
    end
end

os.exit()
