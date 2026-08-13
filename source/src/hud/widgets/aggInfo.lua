Widgets.aggInfo = Widget:new{
    class = 'aggInfo',
    aggData = aggData
}
function Widgets.aggInfo:build()
    self.aggData = aggData
    local agColor = 'orangered'
    local agStat = 'Offline'
    local bubColor = 'orangered'
    if self.aggData.aggState == 1 then
        agColor = 'springgreen'
        agStat = 'Online'
    end
    if self.aggData.aggBubble then
        bubColor = 'springgreen'
    end

    local strings = {}
    strings[#strings+1] = 'AGG INFO'
    strings[#strings+1] = 'Status : <span style="color: ' .. agColor .. ';">' .. agStat .. '</span>'
    strings[#strings+1] = 'Target Alt : ' .. self.aggData.aggTarget
    strings[#strings+1] = 'Current Alt : ' .. self.aggData.aggAltitude
    strings[#strings+1] = 'Pulsors : ' .. self.aggData.aggPulsor
    strings[#strings+1] = 'Strength : ' .. utils.round(self.aggData.aggStrength, 0.01) .. ' %'
    strings[#strings+1] = 'Rate : ' .. utils.round(self.aggData.aggRate * 100, 0.01) .. ' %'
    strings[#strings+1] = 'Power : ' .. utils.round(self.aggData.aggPower * 100, 0.01) .. ' %'
    strings[#strings+1] = 'In Bubble : <span style="color: ' .. bubColor .. ';">' .. tostring(self.aggData.aggBubble) .. '</span>'
    self.rowCount = #strings
    return table.concat(strings, '<br>')
end