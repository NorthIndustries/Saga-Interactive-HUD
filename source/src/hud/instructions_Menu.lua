function HUD.instructionsMenu()
    local gCache = globals
    local svg = svg
    local html = {} 
    html[#html+1] = '<style>' .. HUD.staticCSS.insCss .. '></style>'
    html[#html+1] = [[<div class="infoPanel" style="transform:translate(2vw,2vh)">]]..HUD.staticSVG.instructionsSvg..[[
        </div>]]

    return table.concat(html)
end