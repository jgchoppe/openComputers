-- local component = require("component")
-- local fs = component.filesystem
-- local json = require('serialization')

-- local dbPath = "database.json"

-- local connected = false

-- local fd = {};

-- function ConnectDB()
--     connected = true
--     fd = fs.open(dbPath, "w")

--     while connected do
        
--     end
-- end

-- function CloseDB()
--     connected = false
--     fd.close(fd)
-- end

-- function GetDB()
--     local count = 0
--     local data = ""
--     local r = ""
--     while r do
--         r = fd.read(count)
--         data = data + r
--     end
--     print(data)
-- end


-- ConnectDB()
-- GetDB()