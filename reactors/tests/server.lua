local component = require("component")
local m = component.modem
local event = require("event")

m.open(80)

while(true)
do
    local _, _, from, port, _, message = event.pull("modem_message")
    if message ~= nil then
        print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
    end
end