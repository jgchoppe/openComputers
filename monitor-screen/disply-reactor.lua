local gComponent = require('component')
local gGpu = gComponent.gpu
local gReactor = gComponent.nc_fission_reactor
local gTerm = require("term")

local globalArgv = { ... }

if (globalArgv[1] == nil) then
    print('./display-reactor <REACTOR_NAME>')
    os.exit()
end

function DrawReactorInfo(reactorName, status)
    local bgcolor = gGpu.getBackground()

    gTerm.clear()
    -- Calculate all values before changing the screen
    -- This prevents flickering

    -- Start graphing

    -- Rest screen area and set background color
    -- gGpu.setBackground(bgcolor)
    -- gGpu.fill(x, y, mx, my, " ")

    -- Fill in the bar
    gGpu.setBackground(0xFF0000)
    gGpu.fill(1, 1, 10, 10, " ")

    -- Write the reactor name
    -- gGpu.setBackground(bgcolor)
    -- gGpu.setForeground(0x000000)
    -- gGpu.set(1, 1, reactorName)
end

DrawReactorInfo('my reactor', true)