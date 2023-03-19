local json = require('serialization')
local gComponent = require('component')
local gEvent = require('event')
local gModem = gComponent.modem
local Commands = require('enums.commands')
local globalArgv = { ... }

local timeoutTime = 4

local globalCondition = true
local callbackStatus = false

if (globalArgv[1] == nil) then
    print("reactor-status <REACTOR_NAME>")
    os.exit()
end

-- todo: get manager address
local managerAddress = os.getenv("MAIN_ADDRESS")
if (managerAddress == nil) then
    print('Manager address is null, check env with os.getenv("MAIN_ADDRESS")')
    os.exit()
end

function QueryStatus(firstTime)
    local params = json.serialize({
        command = Commands.CLIReactorStatus,
        data = {
            machineAddress = gModem.address,
            name = globalArgv[1]
        }
    })
    print("params: " .. params)
    local res = gModem.send(managerAddress, 80, params)
    if (res == true) and (firstTime == true) then
        print('Trying to get "' .. globalArgv[1], '" status...')
    end
end


------- LOOP -------

local firstTime = true

while globalCondition do
    QueryStatus(firstTime)
    -- Wait for an inbound message
    local _, _, _, _, _, msgRaw = gEvent.pull(timeoutTime, "modem_message")

    -- Debug mode below
    -- local _, _, _, _, _, msgRaw = gEvent.pull("modem_message")
    -- callbackStatus = true
    -- Debug mode upper

    -- Handle message
    if (msgRaw ~= nil) then
        local res = json.unserialize(msgRaw)
        if (res.command == Commands.CLIReactorStatusCallback) then
            if (res.data.status ~= nil) then
                print('"' .. globalArgv[1], '" status : ' .. res.data.status)
                globalCondition = false
                callbackStatus = true
            else
                print('Callback : Failed when getting "' .. globalArgv[1], '" status.')
            end
        end
    end

    if (callbackStatus == false) then
        firstTime = false
        print('Retrying...')
    end
end

os.exit()
