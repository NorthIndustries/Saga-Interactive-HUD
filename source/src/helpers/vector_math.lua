
function signedRotationAngle(normal, vecA, vecB)
    vecA = vecA:project_on_plane(normal)
    vecB = vecB:project_on_plane(normal)
    return math.atan(vecA:cross(vecB):dot(normal), vecA:dot(vecB))
end

function vectorRotated(vector, direction)
    return vec3(vector):cross(vec3(direction))
end

function projectedDistance(point, position)
    if position == nil then
        position = constructData.constructPosition
    end
    local position = position:project_on_plane(constructData.worldVertical)
    return utils.round(vec3(position - (point:project_on_plane(constructData.worldVertical))):len())
end

function vectorToPoint(point, position)
    local position = position
    if position == nil then
    position = constructData.constructPosition
    end
    return vec3(position - point):normalize()
end

function vectorToPoint2(point, position)
    local position = position
    if position == nil then
    position = constructData.constructPosition
    end
    return vec3(point - position):normalize()
end

function circleNormal(point) --Vector to target level with the planet surface at any altitude. TODO ==inAtmo + sameBody ONLY=============
    local body = findClosestBody(constructData.constructPosition)
    local vecToP = vectorToPoint(point, constructData.constructPosition)
    local pointPlanetCenter = body.center --placeholder until atlas/point system is in, will be the planet center the point is on. or construct if not samebody?
    local vecToA = constructData.constructPosition - pointPlanetCenter
    local vecToB = point - pointPlanetCenter
    local circleNormal = vecToB:cross(vecToA):normalize()

    return (circleNormal:cross(vecToA)):normalize()--:cross(constructData.worldForward)
end

function variousVectors(vector)
    local gCache = globals
    local autoPilot = AutoPilot
    local angleToPoint = -constructData.worldVelocityDirection:angle_between(vector) * constants.rad2deg
    local ninety = (vector - (-constructData.worldVelocityDirection))
    local vecHalf = (ninety + vector):normalize()
    local vecMain = ninety + vector + ninety 
    if gCache.apMode == 'Transfer' or gCache.apMode == 'standby' then
        if constructData.constructSpeed*3.6 >= autoPilot.maxSpaceSpeed then
            spcVector = 'ninety'
            vecMain = (vector:normalize() - (-constructData.worldVelocityDirection:normalize()))
        elseif constructData.constructSpeed*3.6 > (autoPilot.maxSpaceSpeed/3) and constructData.constructSpeed*3.6 < autoPilot.maxSpaceSpeed then
            spcVector = 'main'
            vecMain = ninety + (vector + (ninety * (20 * (1 - utils.clamp(getSpaceVelocityTargetAngle()/45,0,1)))))
        else
            spcVector = 'main2'
            --vecMain = ninety + (vector + (ninety * (20 * (1 - utils.clamp(getSpaceVelocityTargetAngle()/45,0,1)))))
            vecMain = ninety + vector + ninety + ninety
        end
    else
        spcVector = 'none'
        vecMain = ninety + vector + ninety
    end
    return {angleToPoint = angleToPoint, ninety = ninety,vecHalf = vecHalf, vecMain = vecMain} 
end

function getVelocityAngle()
    if constructData.constructSpeed < 1 then
        return 0
    else
        return utils.round(((constructData.worldForward):angle_between(constructData.worldVelocityDirection))*constants.rad2deg)
    end
end

function getVelocityWorldAngle()
    if constructData.constructSpeed < 1 then
        return 0   
    else
        return utils.round(((constructData.worldVelocityDirection:project_on_plane(constructData.worldVertical)):angle_between(constructData.worldVelocityDirection))*constants.rad2deg)
    end
end

function targetAngularVelocityAngle()
    if globals.apMode == 'Transfer' and constructData.constructSpeed > 1 then
        --return utils.round(-variousVectors(target).vecMain:angle_between(constructData.worldForward)*constants.rad2deg,0.01)
        return utils.round(vectorToPoint(variousVectors(AutoPilot.target).vecMain):angle_between(vectorToPoint(constructData.worldForward))*constants.rad2deg,0.01)
    else
        return 0
    end
end

function getTargetWorldAngle()
    local gCache = globals
    local autoPilot = AutoPilot
    local constructData = constructData
    if sameBody then
        return utils.round(vectorToPoint(autoPilot.targetBody.center,autoPilot.target):angle_between(vectorToPoint(autoPilot.targetBody.center,constructData.constructPosition))*constants.rad2deg,0.01)
    else
        return utils.round(vectorToPoint(autoPilot.target,constructData.body.center):angle_between(vectorToPoint(constructData.constructPosition,constructData.body.center))*constants.rad2deg,0.01)
    end
end

function getTargetAngle()
     return utils.round(-math.deg(signedRotationAngle(constructData.worldUp, -constructData.worldForward, vectorToPoint(AutoPilot.target):project_on_plane(constructData.worldVertical))),0.01)
end

function getVelocityTargetAngle()
    --return utils.round(-math.deg(signedRotationAngle(constructData.worldUp, -constructData.worldVelocityDirection:project_on_plane(constructData.worldVertical), vectorToPoint(target):project_on_plane(constructData.worldVertical))),0.01)
    return utils.round(-math.deg(signedRotationAngle(constructData.worldUp, -constructData.worldVelocityDirection:project_on_plane(constructData.worldVertical), circleNormal(AutoPilot.target):project_on_plane(constructData.worldVertical))),0.01)
end

function getSpaceVelocityTargetAngle()
    if constructData.constructSpeed < 1 then
        return 0   
    else
    return utils.round(constructData.worldVelocityDirection:angle_between(-vectorToPoint(AutoPilot.target))*constants.rad2deg,0.01)
    end
end

function getReticle(vector)
    return {constructData.constructPosition.x + vector.x, constructData.constructPosition.y + vector.y, constructData.constructPosition.z + vector.z}
end

function getXYZ(vector)
    return {vector.x, vector.y, vector.z}
end

function getSafeZoneBorder()
    local body = (findClosestBody(constructData.constructPosition).center)
    local mainSafe = vec3(13771471,7435803,-128971)
    local safeTarget = mainSafe
    local safeSize = 18000000
    local planetDist = 400000
    local mainDist = vector.dist(mainSafe,constructData.constructPosition) - safeSize
    local secDist = vector.dist(body,constructData.constructPosition) - planetDist
    local insideSafe = false
    local border = vec3()
    local bodySize = 0
    local borderDist = 0
    local borderVec = vec3()

    if mainDist < secDist then
        safeTarget = mainSafe
        bodySize = safeSize
        borderDist = math.abs(mainDist)
    else
        safeTarget = body
        bodySize = planetDist
        borderDist = math.abs(secDist)
    end

    if mainDist < 0 or secDist < 0 then
        insideSafe = true
    end

    if insideSafe then
        borderVec = (vectorToPoint(safeTarget,constructData.constructPosition):normalize())*borderDist
    else
        borderVec = -(vectorToPoint(safeTarget,constructData.constructPosition):normalize())*borderDist
    end

    return {arBorder = library.getPointOnScreen(getReticle(borderVec)), borderDist = borderDist}

end