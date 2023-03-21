local json = require('serialization')
local event = require('event')
local Commands = require("enums.commands")
local modem = require('modem.modem')
local manager = {}

function manager:findReactor(rName)
    for k, x in pairs(self.reactors) do
        if k == rName then
            return x
        end
    end
    return nil
end

function manager:findManager(mName)
    for k, x in pairs(self.managers) do
        if k == mName then
            return x
        end
    end
    return nil
end

function manager:register(data)
    self.log:debug("data: ", data.machineName, data.machineAddress)
    if data.managerName ~= self.name then
        self.log:warning("action aborted, manager name doesn't match " .. self.name .. ".")
        return
    end

    self.log:info(data.type .. "connection.")

    if data.type == "cli" or data.type == "monitor"
    then
        self.modem:send(data.machineAddress, self.port, {
            command = Commands.RegisterCallback,
            data = {
                managerAddress = self.address,
                success = true
            }
        })
        return
    elseif data.type == "reactor"
    then
        self.reactors[data.machineName] = {
            name = data.machineName,
            address = data.machineAddress
        }
    elseif data.type == "manager"
    then
        self.managers[data.machineName] = {
            name = data.machineName,
            address = data.machineAddress
        }
    else
        self.log:error("wrong register type: " .. data.type)
    end

    self.modem:send(data.machineAddress, self.port, {
        command = Commands.RegisterCallback,
        data = {
            success = true,
            managerAddress = self.address
        }
    })
end

function manager:reactorStart(data)
    local r = self:findReactor(data.name)
    if r == nil then
        return
    end

    self.modem:send(r.address, self.port, {
        command = Commands.ReactorStart
    })
end

function manager:reactorStop(data)
    local r = self:findReactor(data.name)
    if r == nil then
        return
    end

    self.modem:send(r.address, self.port, {
        command = Commands.ReactorStop
    })
end

function manager:reactorStatus(data)
    local r = self:findReactor(data.name)
    if r == nil then
        return
    end

    self.modem:send(r.address, self.port, {
        command = Commands.ReactorStatus,
        data = {
            senderAddress = data.machineAddress
        }
    })
end

function manager:reactorStatusCallback(data)
    self.modem:send(data.senderAddress, self.port, {
        command = Commands.CLIReactorStatusCallback,
        data = {
            status = data.status,
        }
    })
end

function manager:reactorData(data)
    local r = self:findReactor(data.name)
    if r == nil then
        return
    end

    self.modem:send(r.address, self.port, {
        command = Commands.ReactorData,
        data = {
            senderAddress = data.machineAddress
        }
    })
end

function manager:reactorDataCallback(data)
    self.modem:send(data.senderAddress, self.port, {
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
    })
end

local managerHandlers = {
    [Commands.Register] = manager.register,
    [Commands.CLIReactorStart] = manager.reactorStart,
    [Commands.CLIReactorStop] = manager.reactorStop,
    [Commands.CLIReactorStatus] = manager.reactorStatus,
    [Commands.ReactorStatusCallback] = manager.reactorStatusCallback,
    [Commands.CLIReactorData] = manager.reactorData,
    [Commands.ReactorDataCallback] = manager.reactorDataCallback,
}

function manager:handleMsg(data)
    local msg = json.unserialize(data)
    self.log:debug()
    if msg.command == nil then
        return
    end

    if managerHandlers[msg.command] ~= nil then
        managerHandlers[msg.command](self, msg.data)
    end
end


function manager:new (o, name, managerName, port, logger)
    o = o or {}
    if name == nil then
        return nil
    end
    setmetatable(o, self)
    self.__index = self
    self.modem = modem:new(nil, logger)
    self.log = logger
    self.name = name
    self.managerName = managerName
    self.port = port
    self.reactors = {}
    self.managers = {}
    self.address = self.modem:getAddress()
    if managerName ~= nil then
        self.isMain = false
    end
    return 0
end

function manager:start ()
    self.modem:open(self.port)
    if self.isMain == true then
        self.log:info("Main manager is starting with name: " .. self.name .. " on port " .. self.port.tostring().. ".")
    else
        self.log:info("manager is starting with name: " .. self.name .. ". Registering to manager: " .. self.managerName .. " on port " .. self.port.tostring() .. ".")
    end

    local condition = true

    while condition do
        local _, _, from, _, _, data = event.pull("modem_message")
        self.log:info("Got a message from " .. from)
        self.log:debug("data: " .. data)
        if data ~= nil then
            self:handleMsg(data)
        end
    end
end

return manager
