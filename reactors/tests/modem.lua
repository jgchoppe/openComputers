local component = require("component")
local m = component.modem

m.open(80)

m.send("35dbc89b-864a-47b3-8057-9b063e233288", 80, "test")