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
local managerAddress = nil


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
        if (data.managerAddress ~= nil) then
            managerAddress = data.managerAddress
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
    local status = gReactor.isProcessing()

    local params = json.serialize({
        command = "REACTOR_STATUS_CALLBACK",
        data = {
            status = status,
            senderAddress = data.senderAddress
        }
    })

    local res = gModem.send(managerAddress, port, params)
    if (res == true) then
        Log('Successfully sent status to manager')
    else
        Log('Failed when sending status to manager')
    end
end

function GetReactorData(data)
    local status = gReactor.isProcessing()
    local activeFuel, energy, heat, timeCurrent, timeTotal = nil, nil, nil, nil, nil

    if (status == true) then
        activeFuel = gReactor.getFissionFuelName()
        energy = gReactor.getReactorProcessPower()
        heat = gReactor.getReactorCoolingRate()
        timeCurrent = gReactor.getCurrentProcessTime()
        timeTotal = gReactor.getFissionFuelTime()
    end

    print("activeFuel", activeFuel)
    print("energy", energy)
    print("heat", heat)
    print("timeCurrent", timeCurrent)
    print("timeTotal", timeTotal)

    local params = json.serialize({
        command = "REACTOR_DATA_CALLBACK",
        data = {
            isActive = status,
            activeFuel = activeFuel,
            energy = energy,
            heat = heat,
            timeCurrent = timeCurrent,
            timeTotal = timeTotal,
            senderAddress = data.senderAddress
        }
    })

    local res = gModem.send(managerAddress, port, params)
    if (res == true) then
        Log('Successfully sent data to manager')
    else
        Log('Failed when sending data to manager')
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
    [Commands.ReactorData] = GetReactorData,
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

