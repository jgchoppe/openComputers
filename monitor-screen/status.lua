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


local windowWidth = reactorName:len() + 4
local windowHeight = windowWidth / 2;

if (windowHeight % 1 ~= 0) then
    windowHeight = windowHeight - 0.5
end

if (windowHeight % 2 == 0) then
    windowHeight = windowHeight - 1
end

function RegisterCallback(data)
    if (data.success == true) then
        Log('Successfully registered to "' .. managerName .. '" on port: ' .. port)
        print('Currently monitoring : ' .. reactorName)
        if (data.managerAddress ~= nil) then
            managerAddress = data.managerAddress
        end
        callbackRegister = true
        gGpu.setResolution(windowWidth, windowHeight)
    else
        Log('Failed when registering to "' .. managerName .. '" on port "' .. port .. '"')
    end
end

function Log(msg)
    print("[" .. os.date() .. "] " .. msg)
end


--------------------
-- Drawing Functions --
--------------------
local bgcolor = gGpu.getBackground()

function DrawStatus(reactorStatus)
    gTerm.clear()
    local color = 0xFF0000
    if (reactorStatus == true) then
        color = 0x00FF00
    end
    -- Draw a square for status
    gGpu.setBackground(color)
    gGpu.fill(1, 1, windowWidth, windowHeight, " ")

    -- Write the reactor name
    gGpu.setBackground(color)
    gGpu.setForeground(0x000000)
    gGpu.set(3, ((windowHeight - 1) / 2) + 1, reactorName)
end

function ShowCall(callStatus)
    -- local color = 0xFF0000
    -- if (callStatus == true) then
    --     color = 0x00FF00
    -- end
    -- gGpu.setBackground(color)
    -- gGpu.fill(152, 47, 9, 5, " ")
    -- gGpu.setBackground(bgcolor)

    -- os.execute("sleep 0.05")

    -- gGpu.setBackground(bgcolor)
    -- gGpu.fill(152, 47, 9, 5, " ")
    -- gGpu.setBackground(bgcolor)
end

--------------------
-- Loop Functions --
--------------------

---- Query ----

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
    return res

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
    return res
end

---- Callback ----

function StatusCallback(data)
    if (data.status ~= nil) then
        status = data.status
    else
        print('Callback : Failed when getting "' .. reactorName, '" status.')
    end
    DrawStatus(status)
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
    local res = nil
    if (callbackRegister == false) then
        res = Register(firstTime)
        firstTime = false
    else
        res = QueryStatus()
    end

    if (res ~= nil) then
        ShowCall(res)
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
        os.execute("sleep 5")
    end

    if (callbackRegister == false) then
        print('Retrying...')
    end
end