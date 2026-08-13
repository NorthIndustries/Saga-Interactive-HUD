function getConstructData(construct, core)
    local currentRollDeg = getRoll(vec3(core.getWorldVertical()), vec3(construct.getWorldForward()), vec3(construct.getWorldRight()))
    local worldVelocity = vec3(construct.getWorldVelocity())
    local worldForward = vec3(construct.getWorldForward())
    local worldUp = vec3(construct.getWorldUp())
    local worldRight = vec3(construct.getWorldRight())
    local worldVertical = vec3(core.getWorldVertical())
    local constructPosition = vec3(construct.getWorldPosition())
    local _constructData = {
        worldVertical = worldVertical, -- World Vertical, current up vector in world space while on a planet, 0 in space
        worldUp = worldUp, -- World Up
        worldForward = worldForward,
        worldRight = worldRight, -- World Right
        worldVelocity = worldVelocity, -- Velocity
        worldVelocityDirection = worldVelocity:normalize(), -- Velocity Vector against our direction
        worldAngularVelocity = vec3(construct.getWorldAngularVelocity()), -- World Angular Velocity
        worldAirFrictionAngularAcceleration = vec3(construct.getWorldAirFrictionAngularAcceleration()), -- World Angular Velocity
        constructSpeed = worldVelocity:len(), -- Speed in m/s
        currentRollDeg = currentRollDeg, -- Current Roll Deg
        currentRollDegAbs = math.abs(currentRollDeg), -- Current roll Deg Absolute
        currentRollDegSign = utils.sign(currentRollDeg), -- Current Roll Deg Sign
        forwardSpeed = worldVelocity:dot(worldForward),
        lateralSpeed = worldVelocity:dot(-worldRight),
        vertSpeed = worldVelocity:dot(-worldVertical),
        constructMass = construct.getTotalMass(),
        constructPosition = constructPosition,
        atmoDensity = unit.getAtmosphereDensity(),
        burnSpeed = construct.getFrictionBurnSpeed(),
        maxSpeed = construct.getMaxSpeed(),
        gravity = core.getGravityIntensity(),
        maxBrake = construct.getMaxBrake(),
        currentBrake = construct.getCurrentBrake(),
        curThrottle = unit.getThrottle(),
        pvpTimer = construct.getPvPTimer(),
        pvpZone = construct.isInPvPZone(),
        body = findClosestBody(constructPosition),
        altitude = getAltitude(constructPosition),
        rpy = getRPY(worldForward, worldUp, worldRight, worldVertical, worldVelocity)
    }
    _constructData.brakes = getBrakes(_constructData)
    _constructData.orbitalParameters = getOrbitalParameters(_constructData)
    _constructData.orbitFocus = getOrbitFocus(_constructData)
    return _constructData
end

function getBrakes(constructData)
    local dockedMass = 0
    --for _,id in pairs(construct.getDockedConstructs()) do 
    --    dockedMass = dockedMass + construct.getDockedConstructMass(id)
    --end
    --for _,id in pairs(construct.getPlayersOnBoard()) do 
     --   dockedMass = dockedMass + construct.getBoardedPlayerMass(id)
    --end
    local gCache = globals
    local brakeforce = constructData.maxBrake;
    if(brakeforce == nil) then brakeforce = 5000000 end
    
    if gCache.inAtmo then 
    brakeforce = brakeforce / utils.clamp(constructData.constructSpeed/100, 0.1, 1)
    --brakeforce = brakeforce / constructData.atmoDensity
    end

    local c  = 50000 * 2000 / 3600
    local c2 = c * c
    local forwardV = constructData.constructSpeed
    if forwardV > 0 then
        local bt = (brakeforce*-1)/(constructData.constructMass + dockedMass)
        local distance = 0
        local time = 0
        local k1 = c * math.asin(forwardV / c)
        local k2 = c2 * math.cos(k1 / c) / bt
        local t = (c * math.asin(0 / c) - k1) / bt
        local d = k2 - c2 * math.cos((bt * t + k1) / c) / bt
        distance = distance + d
        time = time + t
        --[[local min = math.floor(time / 60)    
        t = t - (60 * min)
        local sec = utils.round(t, 0)
        local time_s = format("%02dm:%02ds", min, sec)]]
        local min = math.floor(time / 60)
        time = time - 60 * min
        local sec =  math.floor(time + 0.5)
        local secForm = '00' .. sec
        local sec = secForm:sub(-2, -1)
        local minForm = '00' .. min
        local min = minForm:sub(-2, -1)
        local time_s = min .. ':' .. sec
    
        local su = math.floor(distance / 200000)
        local distKM = math.floor(distance) / 1000 -- distance in KM
        local distSU = math.floor(distKM) / 200  -- distance in SU
        return {distance = utils.round(distance), distKM = distKM, distSU = distSU, time_s = time_s}
    else
        return {distance = 0, distKM = 0, distSU = 0, time_s = "00m:00s"}
    end
end

function getRPY(forward, up, right, vertical, velocity)
	if velocity:len() < 20 then --TODO will adjust this to include forward speed to limit large yaw jumps when falling straight or lifting off.
        yaw = 0 else
        yaw = -math.deg(signedRotationAngle(up, velocity, forward))
    end
    return {roll = getRoll(vertical, forward, right), pitch = getPitch(vertical, forward, right), yaw = yaw,}
end 

function getPitch(gravityDirection, forward, right)
	local horizontalForward = gravityDirection:cross(right):normalize_inplace()
	local pitch = math.acos(utils.clamp(horizontalForward:dot(-forward), -1, 1))
	if horizontalForward:cross(-forward):dot(right) < 0 then pitch = -pitch end
	return pitch * constants.rad2deg
end

function getRoll(gravityDirection, forward, right)
    local horizontalRight = gravityDirection:cross(forward):normalize_inplace()
    local roll = math.acos(utils.clamp(horizontalRight:dot(right), -1, 1))
    if horizontalRight:cross(right):dot(forward) < 0 then roll = -roll end
    return roll * constants.rad2deg
end

function getThrottle(targetSpeed, direction)
    local gCache = globals
    local speed = constructData.constructSpeed*3.6-20
    if targetSpeed == nil then
        targetSpeed = (constructData.burnSpeed*3.6)-100
    end
    if direction ~= nil then 
        speed = direction*3.6-20
    end
    local speedDiff = (targetSpeed - speed)
    local minmax = 200
    local oneLimeter = 70
    local twoLimeter = 70

    local targetThrottle = utils.clamp((utils.smoothstep(speedDiff, -minmax, minmax) - 0.5) * 2,0,100)

    return targetThrottle
end