AutoPilot = (
function()
    local this = {}

    this.enabled = false
    this.userConfig = {
        maxSpaceSpeed = maxSpaceSpeed,
        maxPitch = maxPitch,
        maxRoll = maxRoll,
        wingStallAngle = wingStallAngle,
        hoverHeight = hoverHeight,
        spaceCapableOverride = spaceCapableOverride,
        shieldManage = shieldManage,
        throttleBurnProtection = throttleBurnProtection,
        autoAGGAdjust = autoAGGAdjust,
        slowFlat = true,
        landingMode = true
    }

    function this:init()
        this:setTargetData(construct.getWorldPosition())
        this.isLastPoint = true

        Config.defaultValues[configDatabankMap.maxSpaceSpeed] = this.userConfig.maxSpaceSpeed
        Config.defaultValues[configDatabankMap.maxPitch] = this.userConfig.maxPitch
        Config.defaultValues[configDatabankMap.maxRoll] = this.userConfig.maxRoll
        Config.defaultValues[configDatabankMap.wingStallAngle] = this.userConfig.wingStallAngle
        Config.defaultValues[configDatabankMap.hoverHeight] = this.userConfig.hoverHeight
        Config.defaultValues[configDatabankMap.spaceCapableOverride] = this.userConfig.spaceCapableOverride
        Config.defaultValues[configDatabankMap.shieldManage] = this.userConfig.shieldManage
        Config.defaultValues[configDatabankMap.throttleBurnProtection] = this.userConfig.throttleBurnProtection
        Config.defaultValues[configDatabankMap.slowFlat] = this.userConfig.slowFlat
        Config.defaultValues[configDatabankMap.autoAGGAdjust] = this.userConfig.autoAGGAdjust
        Config.defaultValues[configDatabankMap.landingMode] = this.userConfig.landingMode
        Config.defaultValues[configDatabankMap.apState] = this.enabled

        EventSystem:register('ConfigDBChanged', this.applyConfig, this)
        this:applyConfig()

        this:resumeFromDatabank()
        this:toggleLandingMode(this.userConfig.landingMode)
    end

    function this:applyConfig()
        this.userConfig.maxSpaceSpeed = Config:getValue(configDatabankMap.maxSpaceSpeed)
        this.userConfig.maxPitch = Config:getValue(configDatabankMap.maxPitch)
        this.userConfig.maxRoll = Config:getValue(configDatabankMap.maxRoll)
        this.userConfig.wingStallAngle = Config:getValue(configDatabankMap.wingStallAngle)
        this.userConfig.hoverHeight = Config:getValue(configDatabankMap.hoverHeight)
        this.userConfig.spaceCapableOverride = Config:getValue(configDatabankMap.spaceCapableOverride)
        this.userConfig.shieldManage = Config:getValue(configDatabankMap.shieldManage)
        this.userConfig.throttleBurnProtection = Config:getValue(configDatabankMap.throttleBurnProtection)
        this.userConfig.slowFlat = Config:getValue(configDatabankMap.slowFlat)
        this.userConfig.autoAGGAdjust = Config:getValue(configDatabankMap.autoAGGAdjust)
        this.userConfig.landingMode = Config:getValue(configDatabankMap.landingMode)
        this:setHoverHeight(this.userConfig.hoverHeight)
        this:updateMaxSpaceSpeed()
    end

    function this:resumeFromDatabank()
        local lastState = Config:getDynamicValue(configDatabankMap.apState)
        if lastState then this:toggleState(lastState) end
        
        local currentTarget = Config:getDynamicValue(configDatabankMap.currentTarget)
        if type(currentTarget) == 'table' then
            if currentTarget.x ~= nil then
                this:setTarget(currentTarget)
            else
                if RouteDatabase:getDatabankName() == currentTarget[3] then
                    this:setActiveRoute(currentTarget[1], currentTarget[2])
                end
            end
        end
    end

    function this:toggleState(state)
        if state == nil then state = not this.enabled end
        this.enabled = state

        if this.enabled then
            this:toggleLandingMode(false)
            SoundSystem:playSound(SoundFiles.autopilotEnabled)
            this:updateMaxSpaceSpeed()
        else
            resetModes()
            SoundSystem:playSound(SoundFiles.autopilotDisabled)
        end
        Config:setDynamicValue(configDatabankMap.apState, this.enabled)
    end
    
    function this:toggleShieldManage(state)
        if state == nil then state = not this.userConfig.shieldManage end
        this.userConfig.shieldManage = state
        Config:setValue(configDatabankMap.shieldManage, state)
    end

    function this:toggleThrottleBurnProtection(state)
        if state == nil then state = not this.userConfig.throttleBurnProtection end
        this.userConfig.throttleBurnProtection = state
        Config:setValue(configDatabankMap.throttleBurnProtection, state)
    end

    function this:toggleSpaceCapableOverride(state)
        if state == nil then state = not this.userConfig.spaceCapableOverride end
        this.userConfig.spaceCapableOverride = state
        Config:setValue(configDatabankMap.spaceCapableOverride, state)
        initEngines()
    end

    function this:toggleSlowFlat(state)
        if state == nil then state = not this.userConfig.slowFlat end
        this.userConfig.slowFlat = state
        Config:setValue(configDatabankMap.slowFlat, state)
    end

    function this:setActiveRoute(routeIndex, pointIndex)
        if pointIndex == nil then pointIndex = 1 end
        this.currentRouteIndex = routeIndex
        this.currentPointIndex = pointIndex
        local targetPos = RouteDatabase:getPointCoordinates(routeIndex, pointIndex)
        if targetPos ~= nil then
            this:setTargetData(targetPos)
            Config:setDynamicValue(configDatabankMap.currentTarget, {this.currentRouteIndex,this.currentPointIndex,RouteDatabase.databank.name})
            this.targetIsLastPoint = this.currentPointIndex == RouteDatabase:getRoutePointCount(routeIndex)
        end
    end

    function this:setTarget(pos)
        this:setTargetData(pos)
        this.targetIsLastPoint = true
        Config:setDynamicValue(configDatabankMap.currentTarget, pos)
    end
    
    function this:updateMaxSpaceSpeed()
        local maxUserSpeed = this.userConfig.maxSpaceSpeed
        local maxConstructSpeed = constructData.maxSpeed
        if maxUserSpeed == 0 then
            this.maxSpaceSpeed = (maxConstructSpeed * 3.6) - 1
        else
            this.maxSpaceSpeed = maxUserSpeed
        end
    end

    function this:onPointReached()
        if not this.targetIsLastPoint then
            if this.currentPointIndex ~= nil then
                this.currentPointIndex = this.currentPointIndex + 1
                this:setActiveRoute(this.currentRouteIndex, this.currentPointIndex)
            end
            SoundSystem:playSound(SoundFiles.waypointReached)
            resetAP()
        else -- Next point doesn't exist
            this:toggleState(false)
            this:toggleLandingMode(true)
            SoundSystem:playSound(SoundFiles.destinationReached)
        end
    end

    -- Triggered if a route is deleted while it's the target
    function this:onRouteUnloaded()
        this.currentRouteIndex = nil
        this.currentPointIndex = nil
        this:toggleState(false)
    end

    function this:setTargetData(pos)
        this.target = vec3(pos)
        this.targetBody = findClosestBody(this.target)
        this.targetAltitude = getAltitude(this.target)
        this.targetLoc = getLoc(this.targetBody, this.targetAltitude)
        this.targetIsLastPoint = false
        --system.setWaypoint('::pos{'..systemId..',0,'..(route.coordinates.x)..','..(route.coordinates.y)..','..(route.coordinates.z)..'}')
    end

    function this:setHoverHeight(height)
        this.userConfig.hoverHeight = height
        if not this.landingMode then
            Nav.axisCommandManager:setTargetGroundAltitude(this.userConfig.hoverHeight)
        end
    end
    
    function this:toggleLandingMode(state)
        if state == nil then state = not this.landingMode end
        this.landingMode = state
        local gCache = globals
        Config:setValue(configDatabankMap.landingMode, state)
        if this.landingMode then
            gCache.altitudeHold = false
            gCache.orbitalHold = false
            gCache.rotationDampening = true
            inputs.brakeLock = false
            inputs.brake = 1
            unit.deployLandingGears()
            if controlMode() == 'cruise' then
                swapControl()
            end
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
            Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal,0)
            Nav.axisCommandManager:setTargetGroundAltitude(-1)
            --Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
            links.electronics:OpenDoors()
        else
            Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
            Nav.axisCommandManager:setTargetGroundAltitude(AutoPilot.userConfig.hoverHeight)
            Nav.axisCommandManager:activateGroundEngineAltitudeStabilization()
            unit.retractLandingGears()
            links.electronics:CloseDoors()
            inputs.brake = 0
        end
    end

    return this
end
)()


function getLoc(body, altitude)
    if body.hasAtmosphere and altitude < body.atmoRadius - body.radius then
        return 'surface'
    elseif not body.hasAtmosphere and altitude < body.surfaceMaxAltitude + 5000 then
        return 'surface'
    else
        return 'space'
    end
end


function orbitHold()
    setTargetOrbitAlt()
    local gCache = globals
    local apoDiff = (gCache.targetOrbitAlt - constructData.orbitFocus.orbitAltTarget)
    local minmax = 20000 + constructData.constructSpeed
    local orbPitch = (utils.smoothstep(apoDiff, -minmax, minmax) - 0.5) * 2 * AutoPilot.userConfig.maxPitch
    if gCache.inAtmo then
        orbPitch = AutoPilot.userConfig.maxPitch
    end
    return orbPitch
end

function altHold()
    local gCache = globals
    local autoPilot = AutoPilot
    local constructData = constructData
    if autoPilot.enabled or gCache.altitudeHold or gCache.orbitalHold or gCache.apMode == 'Orbit' then
        local altitude = constructData.altitude
        local altDiff = (gCache.holdAltitude - altitude)
        local minmax = 500 + constructData.constructSpeed
        gCache.targetPitch = (utils.smoothstep(altDiff, -minmax, minmax) - 0.5) * 2 * AutoPilot.userConfig.maxPitch
        if altDiff < 0 and gCache.inAtmo then
            gCache.targetPitch = gCache.targetPitch/6
        end
        local pitch = constructData.rpy.pitch
        local autoPitchThreshold = 0.1
            if math.abs(gCache.targetPitch - pitch) > autoPitchThreshold then
                if (pitchPID3 == nil) then
                    pitchPID3 = pid.new(0.02, 0, 0.1)
                end
                pitchPID3:inject(gCache.targetPitch - pitch)
                local autoPitchInput2 = pitchPID3:get()
                pitchInput2 = autoPitchInput2
            end
    end
end

function controlMode()
	if unit.getControlMode() == 0 then  --travel = 0 cruise = 1, so make them opposite
		return 'travel'
	else
		return 'cruise'
	end
end

function swapControl()
    unit.cancelCurrentControlMasterMode()
end

function resetAP()
    local gCache = globals
    gCache.aimTarget = 'none'
    gCache.orbitLock = false
    gCache.brakeTrigger = false
    gCache.spaceBrakeTrigger = false
    gCache.stallProtect = false
    gCache.lastProjectedDistance = 10000000
    gCache.missedTarget = false
    gCache.horizontalStopped = false
    gCache.apMode = 'standby'
    gCache.initTurn = true
    inputs.brakeLock = false
end

function resetModes()
    local gCache = globals
    local autoPilot = AutoPilot
    autoPilot.enabled = false
    resetAP()
    gCache.altitudeHold = false
    gCache.orbitalHold = false
    gCache.followMode = false
    gCache.radialIn = false
    gCache.radialOut = false
    gCache.cameraAim = false
    radialMode = 'none'
end

function setTargetOrbitAlt()
    local gCache = globals
    local body = constructData.body
    local targetBody = AutoPilot.targetBody
    local altBuff = constructData.constructMass/2500
    if gCache.apMode == 'Orbit' then
        if sameBody and targetBody.hasAtmosphere then
            gCache.targetOrbitAlt = (targetBody.atmoRadius - targetBody.radius)+1500+altBuff
        elseif not sameBody and body.hasAtmosphere then
            gCache.targetOrbitAlt = (body.atmoRadius - body.radius)+5000+altBuff
        elseif (not sameBody and not body.hasAtmosphere) or (sameBody and not targetBody.hasAtmosphere) then
            gCache.targetOrbitAlt = body.surfaceMaxAltitude + 3000+altBuff
        end
    elseif gCache.manualOrbitAlt ~= 0 then
        gCache.targetOrbitAlt = gCache.manualOrbitAlt
    else
        if body.hasAtmosphere and gCache.manualOrbitAlt == 0 then
            gCache.targetOrbitAlt = (body.atmoRadius - body.radius)+3000+altBuff --- Setup these to be manually adjustable like altHold.
        else
            gCache.targetOrbitAlt = body.surfaceMaxAltitude + 3000+altBuff
        end
    end

end