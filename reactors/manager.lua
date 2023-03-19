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
    FindReactor(data.name)
    m.send()
end

function ReactorStop()

end

function ReactorStatus()
    
end

function Register(data)
    print(data.machineName)
    print(data.address)
    if data.managerName ~= name then
        print("fail")
        return
    end

    if data.type == "cli" then
        m.send(data.address, port, json.serialize({
            address = m.address
        }))
        return
    end
    if data.type == "reactor" then
        if FindReactor(data.machineName) ~= nil then
            m.send(data.address, port, json.serialize({
                command = Commands.RegisterCallback,
                data = {
                    success = false
                }
            }))
        end
        reactors[data.machineName] = {
            name = data.machineName,
            address = data.address
        }
        print("ok")
    else if data.type == "manager" then
        if FindManager(data.machineName) ~= nil then
            m.send(data.address, port, json.serialize({
                command = Commands.RegisterCallback,
                data = {
                    success = false
                }
            }))
        end
            managers[data.machineName] = {
                name = data.machineName,
                address = data.address
            }
        end
    end

    -- m.send("35dbc89b-864a-47b3-8057-9b063e233288", 80, "test")

    m.send(data.address, port, json.serialize({
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
}

function HandleMsg(data, remoteAddress)
    print(data)
    local msg = json.unserialize(data)
    print(msg.command)
    
    if handler[msg.command] ~= nil then
    msg.data.address = remoteAddress
        handler[msg.command](msg.data)
    end
end

-- local exampleData = {
--     command = "test"
-- }

-- local dataToSend = json.serialize(exampleData)

-- HandleMsg(dataToSend)

local globalCondition = true

while globalCondition do
    local _, remoteAddress, _, _, _, data = event.pull("modem_message")
    if data ~= nil then
        HandleMsg(data, remoteAddress)
    end
end
