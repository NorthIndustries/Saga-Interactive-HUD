function HUD.refreshStaticCss()
    local HUDConfig = HUD.Config
    HUD.staticCSS = {
        gradientDefs = [[
            ]]..gradient('mainBg', {
                [0] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,10%)',
                [100] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,5%)',
            }, true)..[[
            ]]..gradient('bg', {
                [0] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 30)..'%,15%)',
                [100] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 30)..'%,10%)',
            }, true)..[[
            ]]..gradient('bgTransparent', {
                [0] = {'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,15%)', 0.5},
                [100] = {'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,10%)', 0.5},
            }, true)..[[
            ]]..gradient('bgStroke', {
                [10] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 50)..'%,50%)',
                [90] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,40%)',
            }, true)..[[
            ]]..gradient('fadeToBg', {
                [60] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,20%)',
                [90] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,15%)',
            }, true)..[[
            ]]..gradient('fadeToBgStroke', {
                [60] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 50)..'%,50%)',
                [90] = 'hsl('..HUDConfig.mainHue..','..(HUDConfig.saturation * 40)..'%,15%)',
            }, true)..[[
        ]],
        menuCss = [[
            .mainMenu {
                font-size: ]]..(HUDConfig.scaleMultiplier * 11)..[[px;
                font-family: Arial;
            }
            .mainMenu text {
                alignment-baseline: middle;
                text-shadow: none;
                stroke-width: 0;
                white-space: pre;
                fill: hsl(0,0%,95%);
                text-anchor: start;
            }
            .menuOption text {
                alignment-baseline: central;
            }
            text.valueText {
                text-anchor: end;
            }
            .mainMenu path {
                fill: hsla(]]..HUDConfig.mainHue..[[,]]..(HUDConfig.saturation * 50)..[[%,80%,0.5);
            }

            /* hover */
            [data-hover=true] text {
                fill: hsl(]]..HUDConfig.mainHue..[[,]]..(HUDConfig.saturation * 50)..[[%,100%);
            }
            [data-hover=true] rect {
                fill: hsla(]]..HUDConfig.mainHue..[[,]]..(HUDConfig.saturation * 50)..[[%,50%,0.5);
            }
            [data-hover=true] path {
                fill: hsla(]]..HUDConfig.mainHue..[[,]]..(HUDConfig.saturation * 50)..[[%,100%,0.7);
            }
            [data-hover=true] rect.separator {
                fill: hsl(0,0%,85%);
            }
            /* active */
            [data-active=true] rect.separator {
                fill: hsl(0,0%,100%);
            }
            /* active hover */
            [data-active=true][data-hover=true] rect {
            }

            rect.inputHold {
                fill: hsl(0,0%,75%)
            }

            text.outlined {
                text-shadow: 0 0 1vh black;
            }
            rect.separator {
                fill: hsl(0,0%,100%);
            }
            
            rect.checkBox {
                fill: hsl(0,0%,70%);
            }
            rect.checkBox.checked {
                fill: hsl(0,0%,100%);
            }
            rect.editableBg {
                fill: hsla(0,0%,0%,0.3);
            }
            rect.editableGlyph {
                fill: hsl(0,0%,95%);
            }

            .menuLegendGlyph {
                overflow: visible;
            }
            text.menuLegendText {
            }
            text.menuLegendKey {
                fill: hsl(0,0%,75%);
                text-anchor: end;
            }
            path.menuLegendKey {
                fill: hsl(0,0%,95%);
            }
            .menuLegend[data-active=true] text, .menuLegend[data-active=true] path {
                fill: hsl(0,0%,100%);
            }
        ]],
        css = [[
            .widget {
                position: absolute;
                white-space: pre;
                font-size: ]]..(HUDConfig.scaleMultiplier * 11)..[[px;
                font-family: Arial;
                color: hsl(0,0%,95%);
                background-color: hsla(0,0%,0%,0.2);
                border:0.1vh;
                border-style: solid;
                border-color: hsl(0,0%,95%);
                text-shadow: 0.2vh 0.2vh 1vh black;
                padding: ]]..(HUDConfig.scaleMultiplier * 5)..[[px;
            }
            .widget.alert {
                border-color: hsl(16,100%,50%);
            }
            .radarRow {
                display: relative;
                height: 1.2vh;
            }
            .radarText {
                position: absolute;
                overflow: hidden;
            }

            .coreInfo {
                text-align: center;
            }

            .dottext {
                position:absolute; width:6vh; height:6vh; left:-6vh; top:-6vh; border-radius:1vh;
            }
            .dot {
                position:absolute; width:3vh; height:3vh; left:-1.5vh; top:-1.5vh; border-radius:1vh;
            }
            .planets {
                position:absolute; width:2vh; height:2vh; left:-1vh; top:-1vh; border-radius:1vh;
            }
            .ptext {
                position:absolute; width:3vh; height:3vh; left:-1.5vh; top:-3vh; border-radius:1vh;
            }
            .mtext {
                position:absolute; width:3vh; height:3vh; left:-1.5vh; top:3vh; border-radius:1vh;
            }
            .debugInfo {
                position:absolute; top:17vh; right:76vw; width:10vw; padding-left: 0.5vh; padding-top: 0.5vh; padding-bottom: 0.5vh; padding-right: 0.5vh; border:0.1vh; border-style: solid; border-color: orangered; background-color: rgba(0,0,0, 0.2);
            }
            .collision {
                position:absolute; top:94vh; right:80vw; width:18vw; padding-left: 1vh; padding-top: 1vh; padding-right: 1vh; padding-bottom: 1vh; border:0.1vh; border-style: solid; border-color: orangered; 
            }
            .radar1 {
                position:absolute; top:83vh; right:25vw; width:12vw; padding-left: 1vh; padding-right: 1vh; padding-top: 1vh; padding-bottom: 1vh; border:0.1vh; border-style: solid; border-color: ivory;
            }
            .radar2 {
                position:absolute; top:83vh; right:38vw; width:12vw; padding-left: 1vh; padding-right: 1vh; padding-top: 1vh; padding-bottom: 1vh; border:0.1vh; border-style: solid; border-color: ivory;
            }
            .radar3 {
                position:absolute; top:83vh; right:51vw; width:12vw; padding-left: 1vh; padding-right: 1vh; padding-top: 1vh; padding-bottom: 1vh; border:0.1vh; border-style: solid; border-color: ivory;
            }
            .speedBar {
                position:absolute; width:11.5vh; height:11.5vh; left:30vh; top:-12vh; border-radius:1vh;
            }
            .throttleBar {
                position:absolute; width:11.5vh; height:11.5vh; left:35vh; top:-8vh; border-radius:1vh;
            }
            .altBar {
                position:absolute; width:11.5vh; height:11.5vh; left:-40vh; top:-12vh; border-radius:1vh;
            }
            .apAlert {
                position:absolute; top:70vh; right:45vw; width:10vw; padding-left: 1vh; padding-top: 1vh; padding-right: 1vh; padding-bottom: 1vh; border:0.2vh; border-style: solid; border-color: orangered;
            }
            .atmoAlert {
                position:absolute; top:71vh; right:58.5vw; width:10vw; padding-left: 0.2vh; padding-top: 0.2vh; padding-right: 0.2vh; padding-bottom: 0.2vh; border:0.1vh;
            }
            .brakeAlert {
                position:absolute; top:75vh; right:45vw; width:10vw; padding-left: 1vh; padding-top: 1vh; padding-right: 1vh; padding-bottom: 1vh;
            }
            
        ]],
        insCss = [[
            .infoPanel{
                position:absolute; width:140vh; height:140; left:0vh; top:0vh; border-radius:1vh;
            }
        ]],
    }
end