local GlobalCommands = 
{
    Register = "REGISTER",
    RegisterCallback = "REGISTER_CALLBACK",

    ReactorStart = "REACTOR_START",
    ReactorStop = "REACTOR_STOP",
    ReactorStatus = "REACTOR_STATUS",

    ManagerStart = "MANAGER_START",
    ManagerStop = "MANAGER_STOP",
    ManagerList = "MANAGER_LIST", -- Only for manager
    ManagerReactorsList = "MANAGER_REACTORS_LIST", -- Only for manager

    -- CLI COMMANDS --
    CLIReactorStart = "CLI_REACTOR_START",
    CLIReactorStop = "CLI_REACTOR_STOP",
    CLIReactorStatus = "CLI_REACTOR_STATUS",
    CLIReactorList = "REACTOR_LIST", -- Only for manager
}

return GlobalCommands