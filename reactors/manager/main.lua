-- Main --
local shell = require('shell')
local arg = require("utils.arg")
local logger = require("utils.logger")
local manager = require("manager")

local function main()
    local scriptArgs = { ... }

    local args, ops = shell.parse(scriptArgs)
    local managerName = ops["manager"] or nil
    local port = arg.getArgNumber(ops["port"], 80)
    local name = args[0]

    local log = logger:new(nil, Logger.LoggerLevel)


    local serv = manager:new(nil, name, managerName, log, port)
    if serv == nil then
        os.exit(1)
    end

    serv:start()
end

main()
