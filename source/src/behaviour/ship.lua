function applyShipInputs()
    local gCache = globals
    local aCache = axis
    local autoPilot = AutoPilot
    -- validate params
    pitchSpeedFactor = math.max(pitchSpeedFactor, 0.01)
    yawSpeedFactor = math.max(yawSpeedFactor, 0.01)
    rollSpeedFactor = math.max(rollSpeedFactor, 0.01)
    torqueFactor = math.max(torqueFactor, 0.01)
    brakeSpeedFactor = math.max(brakeSpeedFactor, 0.01)
    brakeFlatFactor = math.max(brakeFlatFactor, 0.01)
    autoRollFactor = math.max(autoRollFactor, 0.01)
    turnAssistFactor = math.max(turnAssistFactor, 0.01)

    -- final inputs

    local finalPitchInput = inputs.pitch + aCache.pitchAxis + system.getControlDeviceForwardInput()
    local finalRollInput = inputs.roll + aCache.rollAxis + system.getControlDeviceYawInput()
    local finalYawInput = inputs.yaw + aCache.yawAxis - system.getControlDeviceLeftRightInput()
    local finalBrakeInput = inputs.brake + aCache.brakeAxis
    
    local targetAngularVelocity = getTargetAngularVelocity(finalPitchInput, finalRollInput, finalYawInput)
    
    local angularAcceleration = torqueFactor * (targetAngularVelocity - constructData.worldAngularVelocity)
    angularAcceleration = angularAcceleration - constructData.worldAirFrictionAngularAcceleration -- Try to compensate air friction
    local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructData.worldVelocity + brakeFlatFactor * constructData.worldVelocityDirection)
        if not gCache.rotationDampening then
            if inputs.pitch == 0 and inputs.yaw == 0 and inputs.roll == 0 then
                angularAcceleration = vec3()
            end
        end
    if gCache.inOrbit and gCache.orbitalHold and not gCache.brakeTrigger then
        local brakeSensitivity = utils.clamp(((orbitFocus().orbitAltTarget-gCache.targetOrbitAlt)*0.0001)*4,0.01,5)
        brakeAcceleration = vec3(utils.clamp(brakeAcceleration.x,-brakeSensitivity,brakeSensitivity), utils.clamp(brakeAcceleration.y,-brakeSensitivity,brakeSensitivity), utils.clamp(brakeAcceleration.z,-brakeSensitivity,brakeSensitivity))
    end
    if autoPilot.enabled and (brakeCtrl == 12.1 or brakeCtrl == 13.1 or ((brakeCtrl == 0.1) and constructData.vertSpeed*3.6 > -100)) and constructData.constructSpeed*3.6 < constructData.burnSpeed*3.6-50 then
            local brakeSensitivity2 = 2
            brakeAcceleration = vec3(utils.clamp(brakeAcceleration.x,-brakeSensitivity2,brakeSensitivity2), utils.clamp(brakeAcceleration.y,-brakeSensitivity2,brakeSensitivity2), utils.clamp(brakeAcceleration.z,-brakeSensitivity2,brakeSensitivity2))
    end
    if autoPilot.landingMode == true then
        brakeAcceleration = brakeAcceleration*5
    end
    if gCache.altitudeHold then
        brakeAcceleration = -inputs.brake * constructData.worldForward * ((constructData.forwardSpeed + constructData.lateralSpeed)*3.6)
    end
    --printBrake = brakeAcceleration
    applyEngineCommands(targetAngularVelocity, angularAcceleration, brakeAcceleration)
end