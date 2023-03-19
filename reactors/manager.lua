args = { ... }
local json = require('serialization')
local event = require('event')
local Commands = require("enums.commands")
local reactors = {}
local managers = {}
local component = require("component")
local m = component.modem
local computer = component.computer

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


print("Port: " .. port)

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

function Register(data)
    print(data.machineName)
    print(data.machineAddress)
    if data.managerName ~= name then
        print("fail")
        return
    end

    if data.type == "reactor" then
        reactors[data.machineName] = {
            name = data.machineName,
            address = data.machineAddress
        }
        print("ok")
    else if data.type == "manager" then
            print("Not implemented.")
        end
    end

    m.send(data.machineAddress, port, json.serialize({
        command = Commands.RegisterCallback,
        data = {
            success = true,
            managerAddress = computer.address
        }
    }))
    print("send")
end

local handler = {
    [Commands.Register] = Register,
}

function HandleMsg(data)
    print(data)
    local msg = json.unserialize(data)
    print(msg.command)
    
    if handler[msg.command] ~= nil then
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
    local _, _, _, _, _, data = event.pull("modem_message")
    if data ~= nil then
        HandleMsg(data)
    end
end
