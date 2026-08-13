
function onTimerDebug()
end
function onTimerDebug_DISABLED() -- currently disabled
    local gCache = globals
    if gCache.debug then
        debugStr = [[<div class="debugInfo" style="font-size: 0.9vh; color: ivory; text-shadow: 0.2vh 0.2vh 1vh black;">
        SAGA's BASIC DEBUG CRAP DONT JUDGE ME =) <br>
        
        Last Dist  = ]]..tostring(autoPilot.lastProjectedDistance)..[[<br>
        Proj Distance = ]]..tostring(projectedDistance(autoPilot.target)).. [[<br>
        T Distance = ]]..tostring(vector.dist(autoPilot.target,constructData.constructPosition))..[[<br><br>

        targetLocation = ]]..tostring(autoPilot.targetLoc)..[[<br>
        targetAlt = ]]..tostring(getAltitude(autoPilot.target))..[[<br>
        atmo? = ]]..tostring((autoPilot.targetBody.atmoRadius - autoPilot.targetBody.radius))..[[<br>
        Target Angle = ]]..getTargetAngle()..[[<br>
        Aim Target   = ]]..gCache.aimTarget..[[<br>
        SpcVector   = ]]..tostring(spcVector)..[[<br>
        AP Mode      = ]]..tostring(gCache.apMode)..[[<br>
        BrakeCtrl = ]]..tostring(brakeCtrl)..[[<br>
        Spd Control =]]..tostring(SpdControl)..[[<br>
        Brake Trig   = ]]..tostring(gCache.brakeTrigger)..[[<br><br>

        Samebody   = ]]..tostring(sameBody)..[[<br>
        Vel World Angle = ]]..getVelocityWorldAngle()..[[<br>
        Vel to T Angle = ]]..getVelocityTargetAngle()..[[<br>
        Spc to T Angle = ]]..getSpaceVelocityTargetAngle()..[[<br>
        world T Angle = ]]..getTargetWorldAngle()..[[<br>
        Target Altitude = ]]..tostring(gCache.holdAltitude)..[[<br><br>
        
        atmo = ]]..constructData.atmoDensity..[[<br>

        Target Pitch = ]]..tostring(utils.round(gCache.targetPitch))..[[<br>
        Speed = ]]..tostring(utils.round(constructData.constructSpeed),0.01)..[[<br>
        Max S = ]]..tostring(utils.round(constructData.maxSpeed*3.6),0.01)..[[<br>
        Vert Speed = ]]..tostring(utils.round(constructData.vertSpeed),0.01)..[[<br>
        Forward Speed = ]]..tostring(utils.round(constructData.forwardSpeed),0.01)..[[<br>
        Lateral Speed = ]]..tostring(utils.round(constructData.lateralSpeed),0.01)..[[<br><br>

        Burn Spd = ]]..tostring(utils.round(constructData.burnSpeed*3.6))..[[<br><br>

        gravity = ]]..tostring(constructData.gravity)..[[<br>
        Altitude = ]]..tostring(utils.round(constructData.altitude))..[[<br>
        ClosestBody = ]]..tostring(findClosestBody(constructData.constructPosition).name)..[[<br>
        TargetBody = ]]..tostring(autoPilot.targetBody.name)..[[<br>
        atmoAlt = ]]..tostring(findClosestBody(constructData.constructPosition).atmoRadius-findClosestBody(constructData.constructPosition).radius)..[[<br><br>

        OrbitSpd = ]]..tostring((orbitFocus().orbitSpeed*3.6))..[[<br>
        targetOrbit = ]]..tostring(gCache.targetOrbitAlt)..[[<br>
        Orbit Status = ]]..tostring(gCache.inOrbit)..[[<br>
        Apoapsis = ]]..tostring(orbitalParameters().apoapsis.altitude)..[[<br>
        Periapsis = ]]..tostring(orbitalParameters().periapsis.altitude)..[[<br>
        T to Periapsis = ]]..tostring(orbitalParameters().timeToPeriapsis)..[[<br>
        T to Apoapsis = ]]..tostring(orbitalParameters().timeToApoapsis)..[[<br>
        hold = ]]..tonumber(orbitHold())..[[<br><br>

        aggAlt = ]]..tostring(aggData.aggAltitude)..[[<br>
        aggTarget = ]]..tostring(aggData.aggTarget)..[[<br>
        aggStr = ]]..tostring(aggData.aggStrength)..[[<br><br>
        </div>]]

    end
end