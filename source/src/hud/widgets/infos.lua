Widgets.infos = Widget:new{
    class = 'infos',
    constructData = constructData,
    autoPilot = AutoPilot,
    globals = globals
}
function Widgets.infos:build()
    self.globals = globals
    self.constructData = constructData
    self.autoPilot = AutoPilot
    local strings = {}
    local currentRPY = self.constructData.rpy
    strings[#strings+1] = 'Yaw = ' .. utils.round(currentRPY.yaw)
    strings[#strings+1] = 'Pitch = ' .. utils.round(currentRPY.pitch)
    strings[#strings+1] = 'Roll = ' .. utils.round(currentRPY.roll)
    strings[#strings+1] = ''
    strings[#strings+1] = 'Mass = ' .. utils.round(self.constructData.constructMass/1000, 0.001) .. ' T'
    strings[#strings+1] = 'Wing Stall Angle = ' .. self.autoPilot.userConfig.wingStallAngle
    strings[#strings+1] = 'Velocity Angle = ' .. getVelocityAngle()
    strings[#strings+1] = ''
    strings[#strings+1] = 'Burn Protection = ' .. tostring(self.globals.safetyThrottle)
    strings[#strings+1] = 'Max Speed = ' .. tostring(utils.round(self.autoPilot.maxSpaceSpeed))
    strings[#strings+1] = 'Brake Dist = ' .. printDistance(self.constructData.brakes.distance, true)
    if self.autoPilot.target ~= nil then
        local constructSpeed = self.constructData.constructSpeed
        if constructSpeed >= 1 then
            local distanceToTarget = vector.dist(self.autoPilot.target, self.constructData.constructPosition)
            local secondsToTarget = distanceToTarget / constructSpeed
            strings[#strings+1] = ''
            strings[#strings+1] = 'ETA = ' .. formatTimeString(secondsToTarget) .. ' (' .. utils.round(constructSpeed) .. ' m/s)'
        else
            strings[#strings+1] = ''
            strings[#strings+1] = 'ETA = ∞ (0 m/s)'
        end
    end
    self.rowCount = #strings
    return table.concat(strings, '<br>')
end