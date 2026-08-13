Widgets.debugInfo = Widget:new{
    class = 'debugInfo',
    globals = globals,
    constructData = constructData,
    autoPilot = constructData,
    aggData = AutoPilot
}
function Widgets.debugInfo:build()
    local strings = {}
    self.constructData = constructData
    self.aggData = aggData
    self.autoPilot = AutoPilot
    self.globals = globals
    
    strings[#strings+1] = 'DEBUG'
    strings[#strings+1] = 'Last Dist = ' .. tostring(self.globals.lastProjectedDistance)
    strings[#strings+1] = 'Proj Dist = ' .. tostring(projectedDistance(self.autoPilot.target))
    strings[#strings+1] = 'T Dist = ' .. tostring(vector.dist(self.autoPilot.target,constructData.constructPosition))
    strings[#strings+1] = ''
    strings[#strings+1] = 'targetLocation = ' .. tostring(self.autoPilot.targetLoc)
    strings[#strings+1] = 'targetAlt = ' .. tostring(self.autoPilot.targetAltitude)
    strings[#strings+1] = 'atmo = ' .. tostring((self.autoPilot.targetBody.atmoRadius - self.autoPilot.targetBody.radius))
    strings[#strings+1] = 'Target Angle = ' .. getTargetAngle()
    strings[#strings+1] = 'Aim Target = ' .. globals.aimTarget
    strings[#strings+1] = 'SpcVector = ' .. tostring(spcVector)
    strings[#strings+1] = 'AP Mode = ' .. tostring(globals.apMode)
    strings[#strings+1] = 'BrakeCtrl = ' .. tostring(brakeCtrl)
    strings[#strings+1] = 'SpeedCtrl =' ..tostring(SpdControl)
    strings[#strings+1] = 'Brake Trig = ' .. tostring(globals.brakeTrigger)
    strings[#strings+1] = ''
    strings[#strings+1] = 'TAV.x = ' ..tostring(targetAngularVelocity.x)
    strings[#strings+1] = 'TAV.y = ' ..tostring(targetAngularVelocity.y)
    strings[#strings+1] = 'TAV.z = ' ..tostring(targetAngularVelocity.z)
    strings[#strings+1] = ''
    strings[#strings+1] = 'Samebody = ' .. tostring(sameBody)
    strings[#strings+1] = 'Vel World Angle = ' .. getVelocityWorldAngle()
    strings[#strings+1] = 'Vel to T Angle = ' .. getVelocityTargetAngle()
    strings[#strings+1] = 'Spc to T Angle = ' .. getSpaceVelocityTargetAngle()
    strings[#strings+1] = 'world T Angle = ' .. getTargetWorldAngle()
    strings[#strings+1] = 'Target Altitude = ' .. tostring(globals.holdAltitude)
    strings[#strings+1] = ''
    strings[#strings+1] = 'atmo = ' .. constructData.atmoDensity
    strings[#strings+1] = 'Target Pitch = ' .. tostring(utils.round(globals.targetPitch))
    strings[#strings+1] = 'Speed = ' .. tostring(utils.round(constructData.constructSpeed), 0.01)
    strings[#strings+1] = 'Max S = ' .. tostring(utils.round(constructData.maxSpeed * 3.6), 0.01)
    strings[#strings+1] = 'Vert Speed = ' .. tostring(utils.round(constructData.vertSpeed), 0.01)
    strings[#strings+1] = 'Forward Speed = ' .. tostring(utils.round(constructData.forwardSpeed), 0.01)
    strings[#strings+1] = 'Lateral Speed = ' .. tostring(utils.round(constructData.lateralSpeed), 0.01)
    strings[#strings+1] = ''
    strings[#strings+1] = 'Burn Spd = ' .. tostring(utils.round(constructData.burnSpeed * 3.6))
    strings[#strings+1] = ''
    strings[#strings+1] = 'gravity = ' .. tostring(constructData.gravity)
    strings[#strings+1] = 'Altitude = ' .. tostring(utils.round(constructData.altitude))
    strings[#strings+1] = 'ClosestBody = ' .. tostring(constructData.body.name)
    strings[#strings+1] = 'TargetBody = ' .. tostring(self.autoPilot.targetBody.name)
    strings[#strings+1] = 'atmoAlt = ' .. tostring(constructData.body.atmoRadius-constructData.body.radius)
    strings[#strings+1] = ''
    strings[#strings+1] = 'OrbitSpd = ' .. tostring(constructData.orbitFocus.orbitSpeed * 3.6)
    strings[#strings+1] = 'targetOrbit = ' .. tostring(globals.targetOrbitAlt)
    strings[#strings+1] = 'Orbit Status = ' .. tostring(globals.inOrbit)
    strings[#strings+1] = 'Apoapsis = ' .. tostring(constructData.orbitalParameters.apoapsis.altitude)
    strings[#strings+1] = 'Periapsis = ' .. tostring(constructData.orbitalParameters.periapsis.altitude)
    strings[#strings+1] = 'T to Periapsis = ' .. tostring(constructData.orbitalParameters.timeToPeriapsis)
    strings[#strings+1] = 'T to Apoapsis = ' .. tostring(constructData.orbitalParameters.timeToApoapsis)
    strings[#strings+1] = 'hold = ' .. tonumber(orbitHold())
    strings[#strings+1] = ''
    strings[#strings+1] = 'aggAlt = ' .. tostring(aggData.aggAltitude)
    strings[#strings+1] = 'aggTarget = ' .. tostring(aggData.aggTarget)
    strings[#strings+1] = 'aggStr = ' .. tostring(aggData.aggStrength)

    self.rowCount = #strings
    return table.concat(strings, '<br>')
end