function getTargetAngularVelocity(finalPitchInput, finalRollInput, finalYawInput)
    local gCache = globals
    local autoPilot = AutoPilot
    local constructData = constructData
    local aimStrength = 0.3 --export: Aim Strength -- 0.05 to ~3 (no real limit but beyond these values has less/no effect or may cause problems) if your ship often swings past where it's trying to aim and wobbles back and forth, reduce this. if you want it to snap at a point faster/stronger(smaller nimble ships) increase it.
    local finalInput = 
    finalPitchInput * pitchSpeedFactor * constructData.worldRight
    + finalRollInput * rollSpeedFactor * constructData.worldForward
    + finalYawInput * yawSpeedFactor * constructData.worldUp
    targetRoll = 0
    local horizontalRight = constructData.worldVertical:cross(constructData.worldForward):normalize()
    local horizontalForward = constructData.worldVertical:cross(-constructData.worldRight):normalize()
    if (pitchPID2 == nil) then
        pitchPID2 = pid.new(0.02, 0, 0.2)
        rollPID2 = pid.new(0.1, 0, 0.1)
        yawPID2 = pid.new(0.1, 0, 0.1)
    end

    if  constructData.constructSpeed*3.6 < 100 and (gCache.inAtmo or (not constructData.body.hasAtmosphere and constructData.altitude < constructData.body.surfaceMaxAltitude+1000)) and not autoPilot.enabled and autoPilot.userConfig.slowFlat then
        gCache.aimTarget = 'Flat'
        targetAngularVelocity = constructData.worldVertical:cross(constructData.worldUp) + finalInput
    else
        targetAngularVelocity = finalInput
    end

    -- In atmosphere?
    if constructData.worldVertical:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
        local autoRollRollThreshold = 1.0
        -- autoRoll on AND constructData.cRD is big enough AND player is not rolling
        if autoRoll == true and constructData.currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
            local targetRollDeg = utils.clamp(0,constructData.currentRollDegAbs-30, constructData.currentRollDegAbs+30);  -- we go back to 0 within a certain limit
            if (rollPID == nil) then
                rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
            end
            rollPID:inject(targetRollDeg - constructData.currentRollDeg)
            local autoRollInput = rollPID:get()

            targetAngularVelocity = targetAngularVelocity + autoRollInput * constructData.worldForward
        end
        local turnAssistRollThreshold = 20.0
        -- turnAssist AND constructData.cRD is big enough AND player is not pitching or yawing
        if turnAssist == true and constructData.currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
            local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
            local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

            -- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
            local rescaleRollDegAbs = ((constructData.currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
            local rollVerticalRatio = 0
            if rescaleRollDegAbs < 90 then
                rollVerticalRatio = rescaleRollDegAbs / 90
            elseif rescaleRollDegAbs < 180 then
                rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
            end

            rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

            local turnAssistYawInput = - constructData.currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
            local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

            targetAngularVelocity = targetAngularVelocity
                                + turnAssistPitchInput * constructData.worldRight
                                + turnAssistYawInput * constructData.worldUp
        end
    end

    if autoPilot.enabled or gCache.altitudeHold or gCache.orbitalHold then

            local speedCheck = utils.map(utils.clamp(constructData.constructSpeed,80,150), 80, 150, 0, 1)
        if autoPilot.enabled and constructData.constructSpeed > 80 then
            if not gCache.inAtmo or gCache.altitudeHold then
                targetRoll = 0
            --targetRoll = utils.clamp(utils.round(-math.deg(signedRotationAngle(constructData.worldUp, -constructData.worldForward, vectorToPoint(autoPilot.target):project_on_plane(constructData.worldVertical))),0.01)*2,-45,45)*speedCheck
            elseif math.abs(getVelocityTargetAngle()) < 2 or math.abs(getVelocityTargetAngle()) > 170 then
                targetRoll = 0 
            else
                targetRoll = utils.clamp(getVelocityTargetAngle()*2,-AutoPilot.userConfig.maxRoll,AutoPilot.userConfig.maxRoll)*speedCheck
            end
        end
            --rollPID2:inject(targetRoll-constructData.rpy.roll)
            --rollInput2 = rollPID2:get()ee
    end


    if gCache.orbitalHold or gCache.apMode == 'Orbit' then
        aimStrength = utils.clamp(aimStrength-0.1, 0.2,0.4)
        gCache.aimTarget = 'Orbit Hold'

        if not gCache.inOrbit then
            --local orbitfwd = circleNormal(vec3(getReticle(vec3(getXYZ(constructData.worldForward)))))
            --local orbitright = circleNormal(vec3(getReticle(vec3(getXYZ(-constructData.worldRight)))))
            if constructData.altitude < gCache.holdAltitude and constructData.vertSpeed < 0 and gCache.inAtmo then
                gCache.aimTarget = 'Orbit Atmo Pitch'
                --targetAngularVelocity = orbitfwd:rotate((orbitHold())*constants.deg2rad, orbitright):cross(constructData.worldForward)
                targetAngularVelocity = -horizontalForward:rotate((gCache.targetPitch)*constants.deg2rad, horizontalRight):cross(constructData.worldForward)
                if gCache.apMode == 'Orbit' then
                    targetAngularVelocity = ((circleNormal(autoPilot.target)):rotate((gCache.targetPitch)*constants.deg2rad, horizontalRight)):cross(constructData.worldForward)
                end
            elseif constructData.orbitFocus.orbitAltTarget < (gCache.targetOrbitAlt-100) or constructData.orbitFocus.orbitAltTarget > (gCache.targetOrbitAlt+100) then
                gCache.aimTarget = 'Orbit Pitch'
                targetAngularVelocity = -horizontalForward:rotate((orbitHold())*constants.deg2rad, horizontalRight):cross(constructData.worldForward)
                --targetAngularVelocity = orbitfwd:rotate((orbitHold())*constants.deg2rad, orbitright):cross(constructData.worldForward)
                if gCache.apMode == 'Orbit' then
                    targetAngularVelocity = (circleNormal(autoPilot.target)):rotate((orbitHold())*constants.deg2rad, horizontalRight):cross(constructData.worldForward)
                    if  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 and constructData.constructSpeed > 50 then --TODO also Distance Projected maybe?
                        gCache.aimTarget = 'Orbit T2'
                        targetAngularVelocity = ((variousVectors((circleNormal(autoPilot.target))).vecMain)):rotate(((orbitHold())*constants.deg2rad)*1.5, horizontalRight):cross(constructData.worldForward)
                    end
                end
            else
                gCache.aimTarget = 'Orbit Flat'
                targetAngularVelocity = constructData.worldVertical:cross(constructData.worldUp)
                targetAngluarVelocity = targetAngularVelocity + constructData.worldVelocityDirection:cross(-constructData.worldForward)
                if gCache.apMode == 'Orbit' then
                    targetAngularVelocity = (circleNormal(autoPilot.target)):cross(constructData.worldForward)
                    if  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 then
                    targetAngularVelocity = ((variousVectors((circleNormal(autoPilot.target))).vecMain)):cross(constructData.worldForward) + pitchInput2 * constructData.worldRight
                    end
                end
            end
            if (math.abs(getVelocityTargetAngle()) > 80 or constructData.constructSpeed < 10) and gCache.apMode == 'Orbit' then
                targetAngularVelocity = ((circleNormal(autoPilot.target)):project_on_plane(constructData.worldForward)):cross(constructData.worldForward) + finalInput
                targetAngularVelocity = targetAngularVelocity + constructData.worldVertical:cross(constructData.worldUp)      
            end
        else
            targetAngularVelocity =  constructData.worldVelocityDirection:cross(-constructData.worldForward) + finalInput
            if gCache.apMode == 'Orbit' then
                targetAngularVelocity = (circleNormal(autoPilot.target)):cross(constructData.worldForward)
            end
        end
        targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight) + finalInput
        targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)}
    end

    if gCache.altitudeHold then
        gCache.aimTarget = 'Alt Hold'
        targetAngularVelocity = -horizontalForward:rotate((gCache.targetPitch)*constants.deg2rad, horizontalRight):cross(constructData.worldForward) + finalInput
        targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)
    end

    if autoPilot.enabled then
        if gCache.apMode == 'agg' then
            targetAngularVelocity = (circleNormal(autoPilot.target)):cross(constructData.worldForward)
            targetAngularVelocity = targetAngularVelocity + constructData.worldVertical:cross(constructData.worldUp)
        end

        if gCache.apMode == 'reEntry' or gCache.apMode == 'Space Braking' then
            gCache.aimTarget = 'Target'
            targetAngularVelocity = ((circleNormal(autoPilot.target))):cross(constructData.worldForward)
            targetAngularVelocity = targetAngularVelocity + constructData.worldVertical:cross(constructData.worldUp)
        end

        if gCache.apMode == 'Atmo Travel' then
            if math.abs(getTargetAngle()) > 90 then
                pitchRotate = 0 
            else
                pitchRotate = (gCache.targetPitch)*constants.deg2rad
            end
            
            if (math.abs(getVelocityTargetAngle()) > 90 and constructData.constructSpeed > 50) or constructData.constructSpeed < 20 then --TODO also Distance Projected maybe?
                gCache.aimTarget = 'TargetFlat'
                targetAngularVelocity = ((circleNormal(autoPilot.target)):project_on_plane(constructData.worldForward)):cross(constructData.worldForward)
                targetAngularVelocity = targetAngularVelocity + constructData.worldVertical:cross(constructData.worldUp)
            elseif  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 and constructData.constructSpeed > 50 then --TODO also Distance Projected maybe?
                gCache.aimTarget = 'T2'
                targetAngularVelocity = ((variousVectors((circleNormal(autoPilot.target))).vecMain)):rotate(math.min(pitchRotate*1.5,90), horizontalRight):cross(constructData.worldForward) + pitchInput2 * constructData.worldRight
            else
                gCache.aimTarget = 'Pitch Target'
                targetAngularVelocity = ((circleNormal(autoPilot.target)):rotate(pitchRotate, horizontalRight)):cross(constructData.worldForward)
            end

            targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)
        end 

        if sameBody and autoPilot.targetLoc == 'surface' then 
            if gCache.brakeTrigger and gCache.lastProjectedDistance < 600 then
                gCache.aimTarget = 'Brake Landing'
                targetAngularVelocity = (circleNormal(autoPilot.target)):cross(constructData.worldForward)
                targetAngularVelocity = (targetAngularVelocity/3) + vectorToPoint(autoPilot.target):cross(-constructData.worldUp)-- LandingVec TEst

                if (constructData.altitude - getAltitude(autoPilot.target)) < 200 or math.abs(getTargetAngle()) > 90 --[[or not gCache.horizontalStopped]] then
                    gCache.aimTarget = 'Flat'
                    targetAngularVelocity = (circleNormal(autoPilot.target)):cross(constructData.worldForward)
                    targetAngularVelocity = targetAngularVelocity + constructData.worldVertical:cross(constructData.worldUp)
                end
                if (constructData.altitude - getAltitude(autoPilot.target)) < 100 then
                    autoPilot:toggleState(false)
                    autoPilot:toggleLandingMode(true)
                end
            end
        end

        if gCache.apMode == 'Transfer' or (autoPilot.targetLoc == 'space' and not gCache.inAtmo) or (gCache.apMode == 'Space Braking' and (constructData.body.bodyId ~= autoPilot.targetBody.bodyId or vector.dist(constructData.constructPosition,autoPilot.targetBody.center) > 200000 )) then
            if math.abs(getSpaceVelocityTargetAngle()) > 60 or (constructData.constructSpeed*3.6 <= 3000 and autoPilot.targetLoc == 'surface') or (constructData.constructSpeed*3.6 < 500 and autoPilot.targetLoc == 'space') then
                gCache.aimTarget = 'Target'
                targetAngularVelocity = vectorToPoint(autoPilot.target):cross(constructData.worldForward) 
            else
                gCache.aimTarget = 'TCross'
                targetAngularVelocity = variousVectors(vectorToPoint(autoPilot.target)).vecMain:cross(constructData.worldForward)
            end
            if gCache.inAtmo then
                targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)
            end
        end
      if spcVector ~= 'ninety' then
        targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)} + finalInput
      else
        targetAngularVelocity = targetAngularVelocity + finalInput
      end
    end

    if gCache.stallProtect and constructData.constructSpeed > 55 and not gCache.brakeTrigger then --Stall Protection
        gCache.aimTarget = 'Stall Protect'
        targetAngularVelocity = -constructData.worldVelocityDirection:cross(constructData.worldForward) + finalInput
        targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)
    end

    if gCache.radialOut then
        targetAngularVelocity = constructData.worldVertical:cross(constructData.worldForward)
        targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)} + finalInput
    end

    if gCache.radialIn then
        targetAngularVelocity = constructData.worldVertical:cross(-constructData.worldForward)
        targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)} + finalInput
    end

    if gCache.cameraAim then
        if gCache.inAtmo then
            targetAngularVelocity = vec3(system.getCameraWorldForward()):cross(-constructData.worldForward)
            targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)
            targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)}
        else
            targetAngularVelocity = vec3(system.getCameraWorldForward()):cross(-constructData.worldForward)
            targetAngularVelocity = vec3{utils.clamp(targetAngularVelocity.x,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.y,-aimStrength,aimStrength),utils.clamp(targetAngularVelocity.z,-aimStrength,aimStrength)}
        end
    end

    if gCache.followMode then
        targetAngularVelocity = (circleNormal(playerData.playerPosition)):cross(constructData.worldForward)
        targetAngularVelocity = targetAngularVelocity + -horizontalRight:rotate(targetRoll*constants.deg2rad, constructData.worldForward):cross(constructData.worldRight)   
    end

    return targetAngularVelocity
end

-- Engine commands
function applyEngineCommands(targetAngularVelocity, angularAcceleration, brakeAcceleration)
    local gCache = globals
    local aCache = axis
    local autoPilot = AutoPilot
    local keepCollinearity = 1 -- for easier reading
    local dontKeepCollinearity = 0 -- for easier reading
    local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities

    Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
    Nav:setEngineForceCommand('brake', brakeAcceleration)

    -- Autonavigation aka Cruise Control
    local autoNavigationEngineTags = ''
    local autoNavigationAcceleration = vec3()
    local autoNavigationUseBrake = false
    
    local longitudinalPrimaryTags = 'primary'
    local longitudinalSecondaryTags = 'secondary'
    local longitudinalTertiaryTags = 'tertiary'
    local longitudinalEngineTags = 'thrust analog longitudinal'
    local lateralStrafeEngineTags = 'thrust analog lateral'
    local verticalStrafeEngineTags = 'thrust analog vertical'
    local verticalAirfoilTags = 'vertical airfoil'
    local lateralAirfoilTags = 'lateral airfoil'
    local longitudinalCruiseIsOn = Nav.axisCommandManager:getAxisCommandType(axisCommandId.longitudinal) == axisCommandType.byTargetSpeed
    local lateralCruiseIsOn = Nav.axisCommandManager:getAxisCommandType(axisCommandId.lateral) == axisCommandType.byTargetSpeed
    local verticalCruiseIsOn = Nav.axisCommandManager:getAxisCommandType(axisCommandId.vertical) == axisCommandType.byTargetSpeed

    if (longitudinalCruiseIsOn) then
        --print('cruisestuff')
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
        autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal) 
    else
        if aCache.throttle1Axis ~= 0 then
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, aCache.throttle1Axis)
        end
            local acceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
        if ((constructData.atmoDensity >= 0.1 and gCache.advAtmoEngines) or (not gCache.inAtmo and gCache.advSpaceEngines) or (gCache.advSpaceEngines and gCache.advAtmoEngines)) and constructData.curThrottle > 0 then
            if gCache.boostMode == 'primary' then
                Nav:setEngineForceCommand(longitudinalSecondaryTags.. ' , ' .. longitudinalTertiaryTags, vec3(), keepCollinearity)
                if gCache.inAtmo then
                    unit.setEngineThrust('primary', gCache.maxPrimaryKP[1]*constructData.curThrottle)
                else
                    unit.setEngineThrust('primary', gCache.maxPrimaryKP[3]*constructData.curThrottle)
                end
            elseif gCache.boostMode == 'all' then
                Nav:setEngineForceCommand(longitudinalEngineTags, acceleration, keepCollinearity)
            elseif gCache.boostMode == 'locked' then
                Nav:setEngineForceCommand(longitudinalSecondaryTags.. ' , ' .. longitudinalTertiaryTags, acceleration, keepCollinearity)
                if gCache.inAtmo then
                unit.setEngineThrust('primary', gCache.maxPrimaryKP[1])
                else
                unit.setEngineThrust('primary', gCache.maxPrimaryKP[3])
                end
            elseif gCache.boostMode == 'hybrid' then
                local primThrottle = 0
                local secThrottle = 0
                local tertThrottle = 0
                --print('hybridstuff')
                local targetThrottle2 = 0
                local modifierThrottleOne = 0
                local modifierThrottleTwo = 0
                local modifierThrottleThree = 0
                   
                if gCache.inAtmo and gCache.maxTertiaryKP[1] > 0 or not gCache.inAtmo and gCache.maxTertiaryKP[3] > 0 then
                    targetThrottle2 = constructData.curThrottle*3.9
                    modifierThrottleOne = (utils.map(utils.clamp(targetThrottle2,300,330),300,330,0,30))/100
                    modifierThrottleTwo = (utils.map(utils.clamp(targetThrottle2,330,360),330,360,0,30))/100
                    modifierThrottleThree = (utils.map(utils.clamp(targetThrottle2,360,390),360,390,0,30))/100
                    primThrottle = ((utils.map(utils.clamp(targetThrottle2,0,100),0,100,0,70))/100)+modifierThrottleOne
                    secThrottle = ((utils.map(utils.clamp(targetThrottle2,100,200),100,200,0,70))/100)+modifierThrottleTwo
                    tertThrottle = ((utils.map(utils.clamp(targetThrottle2,200,300),200,300,0,100))/100)+modifierThrottleThree
                    else
                    targetThrottle2 = constructData.curThrottle*2.6
                    modifierThrottleOne = (utils.map(utils.clamp(targetThrottle2,200,230),200,230,0,30))/100
                    modifierThrottleTwo = (utils.map(utils.clamp(targetThrottle2,230,260),230,260,0,30))/100
                    primThrottle = ((utils.map(utils.clamp(targetThrottle2,0,100),0,100,0,70))/100)+modifierThrottleOne
                    secThrottle = ((utils.map(utils.clamp(targetThrottle2,100,200),100,200,0,70))/100)+modifierThrottleTwo
                    end
                    if gCache.inAtmo then
                        unit.setEngineThrust('primary', gCache.maxPrimaryKP[1]*primThrottle)
                        unit.setEngineThrust('secondary', gCache.maxSecondaryKP[1]*secThrottle)
                        unit.setEngineThrust('tertiary', gCache.maxTertiaryKP[1]*tertThrottle)
                    else
                        unit.setEngineThrust('primary', gCache.maxPrimaryKP[3]*primThrottle)
                        unit.setEngineThrust('secondary', gCache.maxSecondaryKP[3]*secThrottle)
                        unit.setEngineThrust('tertiary', gCache.maxTertiaryKP[3]*tertThrottle)
                    end


                --[[if gCache.inAtmo and gCache.maxTertiaryKP[1] > 0 or not gCache.inAtmo and gCache.maxTertiaryKP[3] > 0 then
                primThrottle = (utils.map(utils.clamp(constructData.curThrottle,0,60),0,60,0,100))/100
                secThrottle = (utils.map(utils.clamp(constructData.curThrottle,40,100),40,100,0,100))/100
                tertThrottle = (utils.map(utils.clamp(constructData.curThrottle,70,100),70,100,0,100))/100
                else
                primThrottle = (utils.map(utils.clamp(constructData.curThrottle,0,50),0,50,0,100))/100
                secThrottle = (utils.map(utils.clamp(constructData.curThrottle,50,100),50,100,0,100))/100
                end
                if gCache.inAtmo then
                    unit.setEngineThrust('primary', gCache.maxPrimaryKP[1]*primThrottle)
                    unit.setEngineThrust('secondary', gCache.maxSecondaryKP[1]*secThrottle)
                    unit.setEngineThrust('tertiary', gCache.maxTertiaryKP[1]*tertThrottle)
                else
                    unit.setEngineThrust('primary', gCache.maxPrimaryKP[3]*primThrottle)
                    unit.setEngineThrust('secondary', gCache.maxSecondaryKP[3]*secThrottle)
                    unit.setEngineThrust('tertiary', gCache.maxTertiaryKP[3]*tertThrottle)
                end]]
            end
        else
            Nav:setEngineForceCommand(longitudinalEngineTags, acceleration, keepCollinearity)
        end

    end
    --Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 0)

    --Nav:setEngineForceCommand(longitudinalPrimaryTags, constructData.worldForward:normalize()*gCache.lenTest, keepCollinearity)
    --unit.setEngineThrust('primary', maxPrimaryKP[1]*gCache.lenTest)
    
    if (lateralCruiseIsOn) then
        if gCache.lateralState then
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
        else
        Nav:setEngineForceCommand(lateralStrafeEngineTags, vec3(), dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
        autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
        end
    else
        local acceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
        if not gCache.lateralState then
            acceleration = vec3()
        end
        Nav:setEngineForceCommand(lateralStrafeEngineTags, acceleration, keepCollinearity)
        if autoPilot.enabled and gCache.inAtmo then
            local horizontalRight = constructData.worldVertical:cross(constructData.worldForward):normalize()
            local horizontalAcceleration = vec3()
            if getVelocityTargetAngle() < 0 then
                horizontalAcceleration = -horizontalRight*20
            end
            if getVelocityTargetAngle() > 0 then
                horizontalAcceleration = horizontalRight*20
            end   
            Nav:setEngineForceCommand(lateralAirfoilTags, horizontalAcceleration, keepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
        end
    end

    if (verticalCruiseIsOn) then
        if gCache.verticalState or gCache.waterState then
        autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
        else
        autoNavigationEngineTags = autoNavigationEngineTags
        Nav:setEngineForceCommand(verticalStrafeEngineTags, vec3(), dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
        end
        autoNavigationAcceleration = autoNavigationAcceleration + Nav.axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
        
    else
        local acceleration = Nav.axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
        if not gCache.verticalState and not gCache.waterState then
        acceleration = vec3()
        end
        Nav:setEngineForceCommand(verticalStrafeEngineTags, acceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
        if (autoPilot.enabled and gCache.inAtmo) or (gCache.altitudeHold) or (gCache.orbitalHold and gCache.inAtmo) then
            if gCache.apMode == 'Landing' then
            Nav:setEngineForceCommand(verticalAirfoilTags, constructData.worldVertical*20, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
            elseif (constructData.altitude < gCache.holdAltitude or constructData.vertSpeed < -10) then
            Nav:setEngineForceCommand(verticalAirfoilTags, -constructData.worldVertical*20, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
            elseif (gCache.orbitalHold and gCache.inAtmo) then
            Nav:setEngineForceCommand(verticalAirfoilTags, -constructData.worldVertical*20  , keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
            else
            Nav:setEngineForceCommand(verticalAirfoilTags, -constructData.worldVertical*5, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
            end
        end
    end

    -- Cruise control braking
    if (Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
        --Nav.axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - Nav.axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
        Nav.axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) < (constructData.constructSpeed*3.6)-10)
    then
        autoNavigationUseBrake = true
    end

    -- Cruise control engine commands
    if (autoNavigationAcceleration:len() > constants.epsilon) then
        if (inputs.brake ~= 0 or autoNavigationUseBrake or math.abs(constructData.worldVelocityDirection:dot(constructData.worldForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
        then
            autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
        end
        Nav.axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 0)
        Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
    end
    
    -- Rockets
    Nav:setBoosterCommand('rocket_engine')

end