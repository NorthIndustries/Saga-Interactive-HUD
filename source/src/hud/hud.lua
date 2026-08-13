HUD = {
}
HUD.Config = {
    unitWidgetVisible = false,
    mainMenuVisible = false,
    instructionsMenuVisible = false,
    mainHue = 240,
    mainHueShiftRight = 245,
    mainHueShiftLeft = 235,
    saturation = 0,
    scaleMultiplier = nil,
    nativeScaleMultiplier = nil
}

function HUD:init()
    Config.defaultValues[configDatabankMap.hudScale] = 1
    Config.defaultValues[configDatabankMap.unitWidgetVisible] = self.Config.unitWidgetVisible
    Config.defaultValues[configDatabankMap.mainMenuVisible] = self.Config.mainMenuVisible

    EventSystem:register('ConfigDBChanged', self.applyConfig, self)
    
	system.showScreen(1)
    self.updateScale()
    self:applyConfig()

    Widgets = {}
    include('src\\hud\\widgets\\aggInfo.lua')
    include('src\\hud\\widgets\\controls.lua')
    include('src\\hud\\widgets\\core.lua')
    include('src\\hud\\widgets\\debugInfo.lua')
    include('src\\hud\\widgets\\fuelInfo.lua')
    include('src\\hud\\widgets\\infos.lua')
    include('src\\hud\\widgets\\mainMenu.lua')
    include('src\\hud\\widgets\\radarContacts.lua')
    include('src\\hud\\widgets\\warpInfo.lua')
    for i,widget in pairs(Widgets) do
        widget:init()
    end
end

function HUD:applyConfig()
    self.Config.unitWidgetVisible = Config:getValue(configDatabankMap.unitWidgetVisible)
    self.Config.mainMenuVisible = Config:getValue(configDatabankMap.mainMenuVisible)
    self.applyUnitWidget()
end

function HUD.updateScale()
    HUD.screenWidth = system.getScreenWidth()
    HUD.screenHeight = system.getScreenHeight()
    local newScaleMultiplier = HUD.screenHeight / 1080 * Config:getValue(configDatabankMap.hudScale)
    local newNativeScaleMultiplier = HUD.screenHeight / 1080
    if newScaleMultiplier ~= nil and HUD.Config.scaleMultiplier ~= newScaleMultiplier then
        HUD.Config.scaleMultiplier = newScaleMultiplier
        HUD.Config.nativeScaleMultiplier = newNativeScaleMultiplier
        HUD.refreshStaticCss()
    end
end

function HUD.update()
    HUD.updateScale()
    local rendered = '';
    local globals = globals;

    if HUD.Config.instructionsMenuVisible then
        rendered = rendered .. HUD.instructionsMenu()
    else
        rendered = rendered .. HUD.constructDebug()
    
        local widgets = {}
    
        if globals.debug then
            table.insert(widgets, Widgets.debugInfo)
            Widgets.debugInfo.anchor = anchorENUM.topLeft
        end
        table.insert(widgets, Widgets.controls)
        Widgets.controls.anchor = anchorENUM.topRight
        Widgets.controls.width = 180
        if HUD.Config.mainMenuVisible then
            table.insert(widgets, Widgets.mainMenu)
        end
        table.insert(widgets, Widgets.fuelInfo)
        Widgets.fuelInfo.anchor = anchorENUM.topLeft
        Widgets.fuelInfo.width = 220
        table.insert(widgets, Widgets.infos)
        Widgets.infos.width = 150
        Widgets.infos.anchor = anchorENUM.topLeft
        table.insert(widgets, Widgets.core)
        Widgets.core.anchor = anchorENUM.top
        Widgets.core.width = 800
        if links.antigrav then
            table.insert(widgets, Widgets.aggInfo)
            Widgets.aggInfo.anchor = anchorENUM.topLeft
            Widgets.aggInfo.width = 150
        end
        if links.warpdrive ~= nil then
            table.insert(widgets, Widgets.warpInfo)
            Widgets.warpInfo.anchor = anchorENUM.topLeft
            Widgets.warpInfo.width = 180
        end
        if #Radar.radarDynamic > 0 then
            globals.radarD = true
        else
            globals.radarD = false
        end
        if #Radar.radarStatic > 0 then
            globals.radarSt = true
        else
            globals.radarSt = false
        end
        if #Radar.radarAbandoned > 0 then
            globals.radarA = true
        else
            globals.radarA = false
        end
        if #Radar.radarAlien > 0 then
            globals.radarAl = true
        else
            globals.radarAl = false
        end
        if #Radar.radarSpace > 0 then
            globals.radarSp = true
        else
            globals.radarSp = false
        end
        if #Radar.radarFriend > 0 then
            globals.radarF = true
        else
            globals.radarF = false
        end
        if Radar.radar ~= nil and Radar.boxesVisible then
            if globals.radarA then
            table.insert(widgets, Widgets.radarAbandoned)
            end
            if globals.radarSt then
            table.insert(widgets, Widgets.radarStatic)
            end
            if globals.radarD == true then
            table.insert(widgets, Widgets.radarDynamic)
            end
            if globals.radarF then
            table.insert(widgets, Widgets.radarFriend)
            end
            if globals.radarAl then
            table.insert(widgets, Widgets.radarAlien)
            end
            if globals.radarSp then
            table.insert(widgets, Widgets.radarSpace)
            end
            table.insert(widgets, Widgets.radarThreat)
        end
    
        -- Widget rendering, should probably be somewhere else but eh
        local sizeString = 'width:' .. HUD.screenWidth .. 'px; height:' .. HUD.screenHeight .. 'px;'
        rendered = rendered .. '<div style="position:fixed; top:0; left:0; ' .. sizeString .. '">'
        local anchorUsedWidth = {}
        local anchorMaxWidth = {}
        for i, widget in ipairs(widgets) do
            if anchorMaxWidth[widget.anchor] == nil then anchorMaxWidth[widget.anchor] = 0 end
            if anchorMaxWidth[widget.anchor] > 0 then anchorMaxWidth[widget.anchor] = anchorMaxWidth[widget.anchor] + widget.margin end
            anchorMaxWidth[widget.anchor] = anchorMaxWidth[widget.anchor] + widget.width
        end
        for i, widget in ipairs(widgets) do
            if widget.update ~= nil then widget:update() end
            if anchorUsedWidth[widget.anchor] == nil then anchorUsedWidth[widget.anchor] = 0 end
            rendered = rendered .. widget:render(anchorUsedWidth[widget.anchor], anchorMaxWidth[widget.anchor])
            anchorUsedWidth[widget.anchor] = anchorUsedWidth[widget.anchor] + widget.width + widget.margin
        end
    
        rendered = rendered .. '</div>'

    end

    system.setScreen(rendered)
end

function HUD.toggleMainMenu(state)
    if state == nil then state = not HUD.Config.mainMenuVisible end
    HUD.Config.mainMenuVisible = state
    Config:setValue(configDatabankMap.mainMenuVisible, HUD.Config.mainMenuVisible)
end

function HUD.toggleUnitWidget(state)
    if state == nil then state = not HUD.Config.unitWidgetVisible end
    HUD.Config.unitWidgetVisible = state
    Config:setValue(configDatabankMap.unitWidgetVisible, HUD.Config.unitWidgetVisible)
    HUD.applyUnitWidget()
end

function HUD.applyUnitWidget()
    if HUD.Config.unitWidgetVisible then
        unit.showWidget()
    else
        unit.hideWidget()
    end
end

include('src\\hud\\debug.lua')
include('src\\hud\\widget.lua')
include('src\\hud\\menuSystem.lua')
include('src\\hud\\mainMenuActions.lua')
include('src\\hud\\instructions_menu.lua')
include('src\\hud\\static_svg.lua')
include('src\\hud\\static_css.lua')
include('src\\hud\\dynamic_svg.lua')