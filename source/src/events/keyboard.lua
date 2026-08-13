inputs = {
    pitch = 0,
    roll = 0,
    yaw = 0,
    brake = 0,
    manualBrake = false,
    brakeLock = false,
    up = false,
    down = false,
    left = false,
    right = false,
    alt = false,
    shift = false,
    mouseLeft = false
}
function onShiftUp()
    inputs.shift = false
end

function onShiftDown()
    inputs.shift = true
end

function onAltUp()
    inputs.alt = false
end

function onAltDown()
    inputs.alt = true
end

function onMouseUp()
    inputs.mouseLeft = false
end

function onMouseDown()
    inputs.mouseLeft = true
end

function onAlt1()
    if inputs.shift then
        HUD.toggleMainMenu()
    else
        AutoPilot:toggleState()
    end
end

function onAlt2()
    local gCache = globals
    local _inputs = inputs
    gCache.manualOrbitAlt = 0

    if not gCache.altitudeHold and not gCache.followMode then
        if not _inputs.shift then
            gCache.holdAltitude = constructData.altitude
            gCache.altitudeHold = true
        else
            if player.isSeated() == false then
                gCache.followMode = true
            else
                print('not on Remote, follow disabled')
            end
        end
    else
        if not gCache.altitudeHold and gCache.followMode then
            gCache.followMode = false
        elseif gCache.altitudeHold and not gCache.followMode then
            gCache.altitudeHold = false
        end
    end
end

function onAlt3()
    local gCache = globals
    gCache.manualOrbitAlt = 0
    if not gCache.orbitalHold then
        if gCache.spaceCapable then
            resetModes()
            gCache.orbitalHold = true
            setTargetOrbitAlt()
        else
            print('Space thrust not detected: Orbital Hold Disabled')
            gCache.orbitalHold = false
        end
    else
        gCache.orbitalHold = false
    end
end

function onAlt4()
    local gCache = globals
    if not gCache.radialOut and not gCache.radialIn and not gCache.cameraAim then
        gCache.radialMode = 'radial out'
        gCache.radialOut = not gCache.radialOut
    elseif gCache.radialOut then
        gCache.radialMode = 'radial in'
        gCache.radialOut = not gCache.radialOut
        gCache.radialIn = not gCache.radialIn
    elseif gCache.radialIn then
        gCache.radialMode = 'camera aim'
        gCache.cameraAim = not gCache.cameraAim
        gCache.radialIn = not gCache.radialIn
    else
        gCache.radialMode = 'off'
        gCache.cameraAim = not gCache.cameraAim
    end
end

function onAlt5()
    local gCache = globals
    if gCache.boostMode == 'all' then
        gCache.boostMode = 'primary'
    elseif gCache.boostMode == 'primary' then
        gCache.boostMode = 'hybrid'
    elseif gCache.boostMode == 'hybrid' then
        gCache.boostMode = 'locked'
    else gCache.boostMode = 'all'          
    end
end

function onAlt6()
    globals.slowFlat = not globals.slowFlat
end

function onAlt7()
    local gCache = globals
    if gCache.arMode == 'none' then
        gCache.arMode = 'planets'
    elseif gCache.arMode == 'planets' then
        gCache.arMode = 'moons'
    elseif gCache.arMode == 'moons' then
        gCache.arMode = 'both'
    else 
        gCache.arMode = 'none'
    end

end

function onAlt8()
    globals.rotationDampening = not globals.rotationDampening --useful for PvP, probably wont keep on this key?
end

function onAlt9()
    HUD.Config.instructionsMenuVisible = not HUD.Config.instructionsMenuVisible
end

function onWarpDown() -- Warp drive v
    if warpdrive ~= nil then warpdrive.activateWarp() end
end

function onAntigravDown() -- Antigrav v
    if links.antigrav ~= nil then links.antigrav.toggle() end
end

function onLandingGearDown() -- Landing gear v
    if AutoPilot.enabled then AutoPilot:toggleState(false) end
    AutoPilot:toggleLandingMode()
end

function onBoosterDown() -- Booster v
    Nav:toggleBoosters()
end

function onLightDown() -- Light v
    if unit.isAnyHeadlightSwitchedOn() == 1 then
        unit.switchOffHeadlights()
    else
        unit.switchOnHeadlights()
    end
end 

function onMmbDown() -- Stop engines v
    Nav.axisCommandManager:resetCommand(axisCommandId.longitudinal)
end

function onMmbUp() -- Stop engines ^

end

function onUpArrowDown() -- Up Arrow v
    inputs.up = true
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
        Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
        globals.verticalState = true
    end
end

function onUpArrowUp() -- Up Arrow ^
    inputs.up = false
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
        --Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, -1.0)
        Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(currentGroundAltitudeStabilization)
    end
    globals.verticalState = false
end

function onDownArrowDown() -- Down Arrow v
    inputs.down = true
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
        Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, -1.0)
        globals.verticalState = true
    end
end

function onDownArrowUp() -- Down Arrow ^
    inputs.down = false
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
        --Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, 1.0)
        Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(currentGroundAltitudeStabilization)
    end
    globals.verticalState = false
end

function onLeftArrowDown() -- Left Arrow v
    inputs.left = true
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, -1.0)
    end
    globals.lateralState = true
end

function onLeftArrowUp() -- Left Arrow ^
    inputs.left = false
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, 1.0)
    end
    globals.lateralState = false
end

function onRightArrowDown() -- Right Arrow v
    inputs.right = true
    if not HUD.Config.mainMenuVisible then
        Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, 1.0)
    end
    globals.lateralState = true
end

function onRightArrowUp() -- Right Arrow ^
    inputs.right = false
    if not HUD.Config.mainMenuVisible then
    else
        Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, -1.0)
    end
    globals.lateralState = false
end

function onForwardDown() -- Forward v
    inputs.pitch = inputs.pitch - 1
end

function onForwardUp() -- Forward ^
    inputs.pitch = 0
end

function onBackwardDown() -- Backward v
    inputs.pitch = inputs.pitch + 1
end

function onBackwardUp() -- Backward ^
    inputs.pitch = 0
end

function onLeftDown() -- Left v
    inputs.roll = inputs.roll - 1
end

function onLeftUp() -- Left ^
    inputs.roll = 0
end

function onRightDown() -- Right v
    inputs.roll = inputs.roll + 1
end

function onRightUp() -- Right ^
    inputs.roll = 0
end

function onYawLeftDown() -- Yaw Left v
    inputs.yaw = inputs.yaw + 1
end

function onYawLeftUp() -- Yaw Left ^
    inputs.yaw = 0
end

function onYawRightDown() -- Yaw Right v
    inputs.yaw = inputs.yaw - 1
end

function onYawRightUp() -- Yaw Right ^
    inputs.yaw = 0
end

function onGroundAltitudeDownDown() -- Altitude Down v
    Nav.axisCommandManager:updateTargetGroundAltitudeFromActionStart(-1.0)
end

function onGroundAltitudeDownLoop() -- Altitude Down >
    Nav.axisCommandManager:updateTargetGroundAltitudeFromActionLoop(-1.0)
end

function onGroundAltitudeUpDown() -- Altitude Up v
    Nav.axisCommandManager:updateTargetGroundAltitudeFromActionStart(1.0)
end

function onGroundAltitudeUpLoop() -- Altitude Up >
    Nav.axisCommandManager:updateTargetGroundAltitudeFromActionLoop(1.0)
end

function onSpeedUpDown() -- Speed Up v
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0)
    globals.safetyThrottle = false
end

function onSpeedUpLoop() -- Speed Up >
    Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 1.0)
    globals.safetyThrottle = false
end

function onSpeedDownDown() -- Speed Down v
    Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, -5.0)
    globals.safetyThrottle = false
end

function onSpeedDownLoop() -- Speed Down >
    Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, -1.0)
    globals.safetyThrottle = false
end

function onBrakeDown() -- Brake v
    local autoPilot = AutoPilot
    inputs.brake = 1
    inputs.manualBrake = true
    autoPilot.enabled = false
    resetAP()
    if inputs.alt then
        inputs.brakeLock = true
    else
        inputs.brakeLock = false
    end
end

function onBrakeLoop() -- Brake >
    local longitudinalCommandType = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
    if (longitudinalCommandType == axisCommandType.byTargetSpeed) then
        local targetSpeed = Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal)
        if (math.abs(targetSpeed) > constants.epsilon) then
            Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, - utils.sign(targetSpeed))
        end
    end
end

function onBrakeUp() -- Brake ^
    if not inputs.alt then
    inputs.brake = 0
    inputs.manualBrake = false
    end
end