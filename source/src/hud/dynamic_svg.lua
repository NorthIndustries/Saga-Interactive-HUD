
--function dynamicCSS()
 --   local distance = vector.dist(planet.center)
 --   dynamicCSS = [[
 --       .planets {position:absolute; width:6vh; height:6vh; left:-3vh; top:-3vh; border-radius:1vh;
 --       }
 --   ]]
--end

function dynamicSVG()
    local gCache = globals
    local constructData = constructData
    local autoPilot = AutoPilot
    local conSpd = 0
    local maxSpd = 0
    local speedFill = 0
    local rColor = 150
    local gColor = 150
    local bColor = 150
    local maxThrottle = 100
    local curThrottle = utils.round(unit.getThrottle())
    local throttleFill = 0
    local maxAlt = 0
    local altFill = 0
    local curAlt = 0
    local tMode = 'Travel'
    local trgtDistance = 0
    
    if constructData.constructPosition ~= nil and autoPilot.target ~= nil then
        trgtDistance = printDistance((utils.round(vector.dist(autoPilot.target,constructData.constructPosition))), true)
    end
    
    if constructData.constructSpeed ~= nil then
        conSpd = utils.round(constructData.constructSpeed*3.6)
        if gCache.inAtmo then
            maxSpd = utils.round(constructData.burnSpeed*3.6)
        else
            maxSpd = utils.round(constructData.maxSpeed*3.6)
        end
        if conSpd ~= 0 and maxSpd ~= 0 then
            speedFill = utils.clamp(conSpd/maxSpd*200,0,200)
            rColor = utils.round(utils.map(utils.clamp(speedFill,170,200),170,200,150,255))
            gColor = utils.round(utils.map(utils.clamp(speedFill,170,200),170,200,150,40))
            bColor = utils.round(utils.map(utils.clamp(speedFill,170,200),170,200,150,0))
        end
            if controlMode() == 'travel' then
                throttleFill = 200*(math.abs(curThrottle)/100)
            else
                if conSpd*3.6 <= 1000 then
                    maxThrottle = 1000
                elseif conSpd*3.6 <= 5000 then
                    maxThrottle = 5000
                elseif conSpd*3.6 <= 10000 then
                    maxThrottle = 10000
                elseif conSpd*3.6 <= 20000 then
                    maxThrottle = 20000
                else
                    maxThrottle = 30000
                end
                curThrottle = utils.round(math.abs(curThrottle/100))
                throttleFill = utils.clamp(curThrottle/maxThrottle*200,0,200)
            end

            if gCache.showAltitude then
                curAlt = getAltitude()
                if gCache.inAtmo then
                    maxAlt = utils.round(constructData.body.atmoAltitude)
                    altFill = utils.clamp(curAlt/maxAlt*200,0,200)
                elseif constructData.body.hasAtmosphere and gCache.collision ~= nil and curAlt <= 100000 then
                    maxAlt = 100000
                    altFill = utils.clamp(((curAlt-constructData.body.atmoAltitude)/maxAlt)*200,0,200)
                elseif curAlt <= 100000 then
                    maxAlt = 100000
                    altFill = utils.clamp((curAlt/maxAlt)*200,0,200)
                end
            end

            tMode = controlMode()


    end

    HUD.dynamicSVG = {
        targetReticle2 = [[
            <svg viewBox="-77.91 -57.847 135.41 86.458">
            <text style="fill: rgb(204, 204, 204); font-family: Arial, sans-serif; font-size: 30px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0.955784, 0, 0, 1.03899, -3.444869, 2.252162)" x="-77.91" y="-30.551">]]..trgtDistance..[[</text>
            <path style="fill: none; stroke: rgb(204, 204, 204);" d="M -77.91 -22.808 L 0.342 -22.808 L 57.5 28.611"/>
            </svg>
        ]],
        speedBar = [[
            <svg viewBox="-29 -24 72 240" >
            <rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <rect width="5" height="]]..speedFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(]]..tonumber(rColor)..[[, ]]..tonumber(gColor)..[[, ]]..tonumber(bColor)..[[);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <text style="white-space: pre; fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 12px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="1.4" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..conSpd..[[</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">Speed</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="5.5">]]..maxSpd..[[</text>
            </svg>
        ]],
        throttleBar = [[
            <svg viewBox="-29 -24 72 240">
            <rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <rect width="5" height="]]..throttleFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(150, 150, 150);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <text style="white-space: pre; fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 12px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="1.4" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..curThrottle..[[</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">Throttle</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="5.5">]]..maxThrottle..[[</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="200">]]..tMode..[[</text>
            </svg>
        ]],
        altitudeBar = [[
            <svg viewBox="-29 -24 72 240">
            <rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <rect width="5" height="]]..altFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(150, 150, 150);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
            <text style="white-space: pre; fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 12px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="1.4" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..curAlt..[[</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">Altitude</text>
            <text style="fill: rgb(200, 200, 200); font-family: Bank, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="5.5">]]..maxAlt..[[</text>
            </svg>
        ]]
    }
end