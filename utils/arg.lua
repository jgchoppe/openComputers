local arg = {}

function arg.getArgNumber(arg, default)
    if arg ~= nil then
        return arg.tonumber() > 0 and arg.tonumber() or default
    else
        return default
    end
end

return arg
