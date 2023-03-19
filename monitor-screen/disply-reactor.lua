local json = require('serialization')
local gComponent = require('component')
local gTerm = require("term")
local gEvent = require("event")
local gGpu = gComponent.gpu
local gModem = gComponent.modem

local Commands = require('enums.commands')

local globalArgv = { ... }
local port = 80

local globalCondition = true
local callbackRegister = false
local firstTime = true

local timeoutTime = 5

local managerAddress = nil
local status = nil

if (globalArgv[1] == nil) then
    print('./display-reactor <REACTOR_NAME> (<MAIN_MANAGER_NAME default:main)')
    os.exit()
end

function GetArg(arg, default)
    if arg ~= nil then
        return arg
    else
        return default
    end
end
local reactorName = GetArg(globalArgv[1], "reactor")
local managerName = GetArg(globalArgv[2], "main")

function Register(firstTime)
    local params = {
        command = Commands.Register,
        data = {
            type = "monitor",
            machineAddress = gModem.address,
            machineName = nil,
            managerName = managerName
        }
    }
    local res = gModem.broadcast(port, json.serialize(params))
    if (res == true) and (firstTime == true) then
        print("Trying to register...")
    end
end

function RegisterCallback(data)
    if (data.success == true) then
        Log('Successfully registered to "' .. managerName .. '" on port: ' .. port)
        print('Currently monitoring : ' .. reactorName)
        if (data.managerAddress ~= nil) then
            managerAddress = data.managerAddress
        end
        callbackRegister = true
    else
        Log('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
    end
end

function Log(msg)
    print("[" .. os.date() .. "] " .. msg)
end

--------------------
-- Loop Functions --
--------------------

function DrawReactorInfo(reactorName, status)
    local bgcolor = gGpu.getBackground()

    gTerm.clear()
    -- Calculate all values before changing the screen
    -- This prevents flickering

    -- Start graphing

    -- Rest screen area and set background color
    -- gGpu.setBackground(bgcolor)
    -- gGpu.fill(x, y, mx, my, " ")

    -- Fill in the bar
    gGpu.setBackground(0xFF0000)
    gGpu.fill(1, 1, 10, 10, " ")

    -- Write the reactor name
    gGpu.setBackground(bgcolor)
    gGpu.setForeground(0xffffff)
    gGpu.set(1, 1, reactorName)
end

function QueryStatus()
    local params = json.serialize({
        command = Commands.CLIReactorStatus,
        data = {
            machineAddress = gModem.address,
            name = reactorName
        }
    })
    local res = gModem.send(managerAddress, 80, params)
    if (res == true) then
        print('Trying to get "' .. reactorName .. '" status...')
    end
end

function StatusCallback(data)
    if (data.status ~= nil) then
        status = data.status
    else
        print('Callback : Failed when getting "' .. reactorName, '" status.')
    end
    print('Status of "' .. reactorName .. '" : ', status)
end

-------------------
--    Handler    --
-------------------

local handler = {
    [Commands.RegisterCallback] = RegisterCallback,
    [Commands.CLIReactorStatusCallback] = StatusCallback,
}

function HandleMsg(data)
    if (data == nil) then
        return nil
    end
    local msg = json.unserialize(data)
    
    if handler[msg.command] ~= nil then
        handler[msg.command](msg.data)
    end
end

----------------
--    Main    --
----------------
gModem.open(port)


while globalCondition do
    if (callbackRegister == false) then
        Register(firstTime)
        firstTime = false
    else
        QueryStatus()
    end
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull(timeoutTime, "modem_message")

    -- Debug mode below
    -- local _, _, _, _, _, msgRaw = gEvent.pull( "modem_message")
    -- Debug mode upper

    -- Handle message
    if (msgRaw ~= nil) then
        -- LogMsg(msgRaw)
        HandleMsg(msgRaw)
    end

    if (callbackRegister == false) then
        print('Retrying...')
    end
end