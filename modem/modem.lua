local component = require("component")
local json = require("serialization")

local modem = {}

function modem:new(o, logger)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.m = component.modem
    self.log = logger
    self.address = self.m.address
    return o
end

function modem:send(ip, port, oData)
    local data = json.serialize(oData)
    self.m.send(ip, port, data)
    self.log:info("message sent to " .. ip .. ":" .. port.tostring() .. ".")
    self.log:debug("data sent: ", data)
end

function modem:broadcast(port, oData)
    local data = json.serialize(oData)
    self.m.broadcast(port, data)
    self.log:info("message sent to port" .. port.tostring() .. ".")
    self.log:debug("data sent: ", data)
end

function modem:getAddress()
    return self.address
end

function modem:open(port)
    self.m.open(port)
end

return modem
