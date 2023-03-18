-- Print helper message
function PrintHelp()

end

-- Validate args and check for help command
function ValidateArgs(args)
    if (args[1] == nil) or (string.upper(args[1]) == "-h") then
        PrintHelp()
        os.exit()
    end

    return true
end


-------------------
-- Main function --
-------------------

local globalArgv = { ... }

ValidateArgs(globalArgv)



local name = globalArgv[1] 