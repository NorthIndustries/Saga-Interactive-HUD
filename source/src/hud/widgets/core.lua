Widgets.core = Widget:new{
    class = 'coreInfo',
    core = links.core,
    shield = links.shield,
    constructData = constructData
}
function Widgets.core:build()
    local coreHealth = math.abs((self.core.getCoreStressRatio()*100)-100)
    local coreStress = self.core.getCoreStress()
    local coreMaxStress = self.core.getMaxCoreStress()

    if constructData.pvpZone == 1 then
        self.class = 'coreInfo alert'
    end

    local cColor = 'springgreen'
    if coreHealth <= 20 then
        cColor = 'orangered'
    elseif coreHealth <= 50 then
        cColor = 'goldenrod'
    end

    local strings = {}
    strings[#strings+1] = 'Core : <span style="color:' .. cColor .. ';">%' .. coreHealth .. '</span>'
    strings[#strings+1] = 'Core Stress: <span style="color:' .. cColor .. ';">' .. (coreMaxStress - coreStress) .. '</span> / ' .. coreMaxStress

    if self.shield ~= nil then
        local shp = self.shield.getShieldHitpoints()
        local mshp = self.shield.getMaxShieldHitpoints()
        local sHealth = ((shp / mshp) * 100)
        local shieldActiveColor = 'orangered'
        local shieldColor = 'springgreen'
        if sHealth <= 20 then
            shieldColor = 'orangered'
        elseif sHealth <= 50 then
            shieldColor = 'goldenrod'
        end
        if self.shield.isActive() == 1 then
            shieldActiveColor = 'springgreen'
        end

        local shieldStateStr = '<span style="color:' .. shieldActiveColor .. ';">Shield</span>'
        local shieldHealthStr = '<span style="color: '..shieldColor..';">'..sHealth..'%</span>'
        local shieldHpStr = '<span style="color: ' .. shieldColor .. ';">' .. shp .. '</span> / ' .. mshp

        strings[#strings+1] = shieldStateStr .. ': ' .. shieldHealthStr
        strings[#strings+1] = 'Shield Health: ' .. shieldHpStr
    end

    strings[#strings+1] = 'PvP Timer: ' .. constructData.pvpTimer

    self.rowCount = #strings
    return table.concat(strings, ' | ')
end