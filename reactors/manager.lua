args = { ... }
local json = require('serialization')
local event = require('event')
local Commands = require("enums.commands")
local reactors = {}
local managers = {}

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

function Register()
    print("Register")
end

local handler = {
    [Commands.Register] = Register,
}

function HandleMsg(data)
    local msg = json.unserialize(data)
    
    if handler[msg.command] ~= nil then
        handler[msg.command]()
    end
end

local exampleData = {
    command = "test"
}

local dataToSend = json.serialize(exampleData)

HandleMsg(dataToSend)

local globalCondition = true

-- while globalCondition do
--     local _, _, _, _, _, data = event.pull("modem_message")
--     if data ~= nil then
--         HandleMsg(data)
--     end
-- end
