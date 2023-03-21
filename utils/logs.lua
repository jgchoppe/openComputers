local ansicolors = require('ansicolors')

logger = {}

logger.LoggerLevel =
{
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
}

function logger:new(o, level)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.level = level
    return o
end

function logger:debug(msg, ...)
    local args = {...}
    if self.level <= loggerLevel.DEBUG then
        return print(ansicolors.blue .. "[DEBUG]:", msg, table.unpack(args) .. ansicolors.reset)
    end
end

function logger:info(msg, ...)
    local args = {...}
    if self.level <= loggerLevel.INFO then
        return print("[INFO]:", msg, table.unpack(args))
    end
end

function logger:warning(msg, ...)
    local args = {...}
    if self.level <= loggerLevel.WARNING then
        return print(ansicolors.red .. "[WARNING]:", msg, table.unpack(args) .. ansicolors.reset)
    end
end

function logger:error(msg, ...)
    local args = {...}
    if self.level <= loggerLevel.ERROR then
        return print(ansicolors.red .. "[ERROR]:", msg, table.unpack(args) .. ansicolors.reset)
    end
end

function logger:critical(msg, ...)
    local args = {...}
    if self.level <= loggerLevel.CRITICAL then
        print(ansicolors.red .. "[CRITICAL]:", msg, table.unpack(args) .. ansicolors.reset)
        os.exit(1)
    end
end

return logger
