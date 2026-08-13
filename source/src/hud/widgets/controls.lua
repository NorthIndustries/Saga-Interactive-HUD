Widgets.controls = Widget:new{
    class = 'controlsBox',
    autoPilot = AutoPilot,
    globals = globals
}
function Widgets.controls:build()
    local strings = {}
    strings[#strings+1] = 'Alt-1| Toggle AP - ' .. tostring(self.autoPilot.enabled)
    strings[#strings+1] = 'Alt-2| Altitude Hold - ' .. tostring(self.globals.altitudeHold)
    strings[#strings+1] = 'Alt-3| Orbital Hold - ' .. tostring(self.globals.orbitalHold)
    strings[#strings+1] = 'Alt-4| Radial Hold - ' .. tostring(self.globals.radialMode)
    strings[#strings+1] = 'Alt-5| Engine Mode - ' .. tostring(self.globals.boostMode)
    strings[#strings+1] = 'Alt-6| Slow Flat - ' .. tostring(self.autoPilot.userConfig.slowFlat)
    strings[#strings+1] = 'Alt-7| AR Mode - ' .. tostring(self.globals.arMode)
    strings[#strings+1] = 'Alt-8| Rotation Damp. - ' .. tostring(self.globals.rotationDampening)
    strings[#strings+1] = 'Alt-9| Instructions'
    strings[#strings+1] = ''
    strings[#strings+1] = 'Alt-Shift-1| Toggle Main Menu'
    strings[#strings+1] = 'Alt-Shift-2| Follow Mode - ' .. tostring(self.globals.followMode)
    strings[#strings+1] = ''
    strings[#strings+1] = 'G| Parking - ' .. tostring(self.autoPilot.landingMode)
    strings[#strings+1] = 'Alt + Ctrl| Brake Lock - ' .. tostring(inputs.manualBrake)
    self.rowCount = #strings
    return table.concat(strings, '<br>')
end