args = { ... }
local json = require('serialization')
local event = require('event')
local Commands = require("enums.commands")
local reactors = {}
local managers = {}
local component = require("component")
local m = component.modem

local name = args[1]
if name == nil then
    print("No Name Provided.")
    os.exit()
end

local managerName = args[2]
local isMain = true

function GetArgNumber(arg, default)
    if arg ~= nil then
        return arg + 0
    else
        return default
    end
end

local port = GetArgNumber(args[3], 80)
local monitorPort = 81

print("Port: " .. port)

m.open(monitorPort)
m.open(port)

if managerName ~= nil then
    isMain = false
end

function Start()
    if isMain == true then
        print("Main Manager is starting with name: " .. name)
    else
        print("Manager is starting with name: " .. name .. ". Registering to manager: " .. managerName)
    end
end

Start()

function FindReactor(rName)
    for k, x in pairs(reactors) do
        if k == rName then
            return x
        end
    end
    return nil
end

function FindManager(mName)
    for k, x in pairs(managers) do
        if k == mName then
            return x
        end
    end
    return nil
end

function ReactorStart(data)
    local r = FindReactor(data.name)
    if r == nil then
        return
    end

    m.send(r.address, port, json.serialize({
        command = Commands.ReactorStart
    }))
end

function ReactorStop(data)
    local r = FindReactor(data.name)
    if r == nil then
        return
    end

    m.send(r.address, port, json.serialize({
        command = Commands.ReactorStop
    }))
end

function ReactorStatus(data)
    print("Getting ReactorStatus request...")
    local r = FindReactor(data.name)
    if r == nil then
        return
    end

    print(r.name)
    print(r.address)

    m.send(r.address, port, json.serialize({
        command = Commands.ReactorStatus,
        data = {
            senderAddress = data.machineAddress
        }
    }))
    print("Sending ReactorStatus request...")
end

function ReactorStatusCallback(data)
    m.send(data.senderAddress, port, json.serialize({
        command = Commands.CLIReactorStatusCallback,
        data = {
            status = data.status,
        }
    }))
end

function ReactorData(data)
    print("Getting ReactorData request...")
    local r = FindReactor(data.name)
    if r == nil then
        return
    end

    print(r.name)
    print(r.address)

    m.send(r.address, port, json.serialize({
        command = Commands.ReactorData,
        data = {
            senderAddress = data.machineAddress
        }
    }))
    print("Sending ReactorData request...")
end

function ReactorDataCallback(data)
    m.send(data.senderAddress, port, json.serialize({
        command = Commands.CLIReactorDataCallback,
        data = {
            isActive = data.isActive,
            activeFuel = data.activeFuel,
            energy = data.energy,
            heat = data.heat,
            timeCurrent = data.timeCurrent,
            timeTotal = data.timeTotal,
            status = data.status,
        }
    }))
end

function Register(data)
    print(data.machineName)
    print(data.machineAddress)
    if data.managerName ~= name then
        print("fail")
        return
    end

    if data.type == "cli" or data.type == "monitor" then
        print(data.type .. " connection")
        print(data.machineAddress)
        m.send(data.machineAddress, port, json.serialize({
            command = Commands.RegisterCallback,
            data = {
                managerAddress = m.address,
                success = true
            }
        }))
        return
    end
    if data.type == "reactor" then
        reactors[data.machineName] = {
            name = data.machineName,
            address = data.machineAddress
        }
        print("ok")
    else if data.type == "manager" then
        if FindManager(data.machineName) ~= nil then
            m.send(data.machineAddress, port, json.serialize({
                command = Commands.RegisterCallback,
                data = {
                    success = false
                }
            }))
        end
            managers[data.machineName] = {
                name = data.machineName,
                address = data.machineAddress
            }
        end
    end

    -- m.send("35dbc89b-864a-47b3-8057-9b063e233288", 80, "test")

    m.send(data.machineAddress, port, json.serialize({
        command = Commands.RegisterCallback,
        data = {
            success = true,
            managerAddress = m.address
        }
    }))
end

local handler = {
    [Commands.Register] = Register,
    [Commands.CLIReactorStart] = ReactorStart,
    [Commands.CLIReactorStop] = ReactorStop,
    [Commands.CLIReactorStatus] = ReactorStatus,
    [Commands.ReactorStatusCallback] = ReactorStatusCallback,
    [Commands.CLIReactorData] = ReactorData,
    [Commands.ReactorDataCallback] = ReactorDataCallback,
}

function HandleMsg(data)
    print(data)
    local msg = json.unserialize(data)
    -- print(msg.command)
    if msg.command == nil then
        return
    end
    
    if handler[msg.command] ~= nil then
        handler[msg.command](msg.data)
    end
end

local globalCondition = true

while globalCondition do
    local _, _, _, _, _, data = event.pull("modem_message")
    if data ~= nil then
        HandleMsg(data)
    end
end
