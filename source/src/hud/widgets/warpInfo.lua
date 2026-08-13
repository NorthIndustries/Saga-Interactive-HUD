Widgets.warpInfo = Widget:new{
    class = 'warpInfo',
    warpData = warpData
}
function Widgets.warpInfo:build()
    self.warpData = warpData
    local tColor = 'ivory'
    if self.warpData.warpStatus ~= 'Ready' then
        tColor = 'orangered'
    else
        tColor = 'springgreen'
    end

    local strings = {}
    strings[#strings+1] = 'WARP DRIVE INFO'
    strings[#strings+1] = 'Status : <span style="color: ' .. tColor .. ';">' .. self.warpData.warpStatus .. '</span>'
    strings[#strings+1] = 'Distance : ' .. printDistance(self.warpData.warpDistance, true)
    strings[#strings+1] = 'Destination : ' .. self.warpData.warpDestination
    strings[#strings+1] = 'Cells Available : ' .. self.warpData.warpCells
    strings[#strings+1] = 'Cells Needed : ' .. self.warpData.warpCellsNeeded
    strings[#strings+1] = '<span style="color: ' .. tColor .. ';">ENGAGE WARP - ALT-J</span>'
    self.rowCount = #strings
    return table.concat(strings, '<br>')
end