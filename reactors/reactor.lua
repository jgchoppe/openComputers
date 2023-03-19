local json = require('serialization')
local gComponent = require('component')
local gEvent = require('event')
local gTerm = require("term")
local gGpu = gComponent.gpu
local gModem = gComponent.modem
local gReactor = gComponent.nc_fission_reactor

local Commands = require('enums.commands')

local globalArgv = { ... }
local port = 80
local timeoutTime = 4 -- in seconds

local globalCondition = true
local callbackRegister = false
local firstTime = true

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
    print('./reactor.lua <REACTOR_NAME> <MANAGER_NAME>')
end

-- Validate args and check for help command
function ValidateArgs(args)
    if ((args[1] == nil or args[2] == nil) or (string.upper(args[1]) == "-h")) and (args[1] ~= "debug") then
        PrintHelp()
        os.exit()
    end

    return true
end

function Register(firstTime)
    local params = {
        command = Commands.Register,
        data = {
            type = "reactor",
            machineAddress = gModem.address,
            machineName = reactorName,
            managerName = managerName
        }
    }
    local res = gModem.broadcast(port, json.serialize(params))
    if (res == true) and (firstTime == true) then
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


function Log(msg)
    print("[" .. os.date() .. "] " .. msg)
end


--------------------
-- Loop Functions --
--------------------


function RegisterCallback(data)
    if (data.success == true) then
        Log('Successfully registered to "' .. managerName .. '" on port: ' .. port)
        print('Reactor name: ' .. reactorName)
        if (data.managerAdress ~= nil) then
            managerAdress = data.managerAdress
        end
        callbackRegister = true
    else
        Log('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
    end
end

function StartReactor()
    Log('Start reactor')
    gReactor.activate()
end

function StopReactor()
    Log('Stop reactor')
    gReactor.deactivate()
end

function GetReactorStatus(data)
    local status = true

    print('Get status :', status)
    print('commands test', Commands.ReactorStatusCallback)
    local res = gModem.send(managerAdress, port, json.serialize({
        command = Commands.ReactorStatusCallback,
        data = {
            status = status,
            senderAddress = data.senderAddress
        }
    }))
    if (res == true) then
        Log('Successfully sent status to manager')
    else
        Log('Failed when sending status to manager')
    end
end


-------------------
--    Handler    --
-------------------

local handler = {
    [Commands.RegisterCallback] = RegisterCallback,
    [Commands.ReactorStart] = StartReactor,
    [Commands.ReactorStop] = StopReactor,
    [Commands.ReactorStatus] = GetReactorStatus,
}

function HandleMsg(data)
    if (data == nil) then
        return nil
    end
    print('data', data)
    local msg = json.unserialize(data)
    
    if handler[msg.command] ~= nil then
        handler[msg.command](msg.data)
    end
end


--------------------
--      Main      --
--------------------
gModem.open(port)

ValidateArgs(globalArgv)

gTerm.clear()

-- Main Loop

while globalCondition do
    if (callbackRegister == false) then
        Register(firstTime)
        firstTime = false
    end
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull(timeoutTime, "modem_message")

    -- Debug mode below
    -- local _, _, _, _, _, msgRaw = gEvent.pull( "modem_message")
    -- callbackRegister = true
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

os.exit()

