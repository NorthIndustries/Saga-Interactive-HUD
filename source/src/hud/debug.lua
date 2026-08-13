function HUD.constructDebug()
    local gCache = globals
    local autoPilot = AutoPilot
    local tankData = tankData
    local constructData = constructData
    local warpData = warpData
    local bDist = constructData.brakes.distance
    local cPitch = utils.round(constructData.rpy.pitch)
    local textSize = 1
    --local gCache.targetPitch = math.deg(signedRotationAngle(constructData.worldRight, variousVectors(target):project_on_plane(constructData.worldForward), constructData.worldForward))
    --local horizontalRight = constructData.worldVertical:cross(constructData.worldForward):normalize()
    --local horizontalForward = constructData.worldVertical:cross(-constructData.worldRight):normalize_inplace()
    --local brakeTags = 'brake'
    updateTanksCo()
    --radarCleanCo()
    --gCache.maxBrakeKP = construct.getMaxThrustAlongAxis(brakeTags, {vec3(construct.getWorldVelocity()):unpack()})
    --rdata = activeRadar.getWidgetData()

    --if not radarSpawn then
    --    radarWidgetCreate()
    --    radarSpawn = true
    --end
    if constructData.altitude > 100000 then
        gCache.showAltitude = false
    else
        gCache.showAltitude = true
    end

    local conSpd = 0
    local maxSpd = 0
    local maxThrottle = 100
    local curThrottle = utils.round(unit.getThrottle())
    local maxAlt = 0
    local curAlt = 0

    local html = {}
    html[#html+1] = [[<div class="speedBar" style="transform:translate(50vw,50vh)">]]..HUD.dynamicSVG.speedBar..[[
    </div>]]
    html[#html+1] = [[<div class="throttleBar" style="transform:translate(50vw,50vh)">]]..HUD.dynamicSVG.throttleBar..[[
    </div>]]
 
    if gCache.showAltitude then
        local planetStr = ''
        local bDist = utils.round(constructData.brakes.distance*1.1)
        local bColor = 'ivory'
        if constructData.body.hasAtmosphere then
            local atmoColDist = utils.round(vector.dist(constructData.body.center,constructData.constructPosition)-(constructData.body.atmoRadius))
            planetStr = [[Atmo Dist = ]]..printDistance(atmoColDist, true)..[[<br>]]
            if bDist > atmoColDist and atmoColDist > 0 then
                bColor = 'orangered'
            end
        else
            local moonColDist = utils.round(vector.dist(constructData.body.center,constructData.constructPosition)-(constructData.body.radius*1.05))
            planetStr = [[Surf Dist ~ ]]..printDistance(moonColDist, true)..[[<br>]]
            if bDist > moonColDist and moonColDist > 0 then
                bColor = 'orangered'
            end
        end
    html[#html+1] = [[<div class="altBar" style="transform:translate(50vw,50vh)">]]..HUD.dynamicSVG.altitudeBar..[[
        </div>]]
    html[#html+1] = [[<div class="atmoAlert" style="font-size: ]]..textSize..[[vh; color: ivory; text-shadow: 0.2vh 0.2vh 1vh black;">
        Brake Dist = <span style="color: ]]..bColor..[[;">]]..printDistance(bDist, true)..[[<br></span>]]
        ..planetStr..[[
        </div>]]
    end
    html[#html+1] = [[<div class="atmoAlert" style="transform:translate(27vw,1vh); font-size: ]]..textSize..[[vh; color: ivory; text-align: right; text-shadow: 0.2vh 0.2vh 1vh black;">
    Vertical Speed: ]]..(utils.round(constructData.vertSpeed*3.6))..[[
    </div>]]

    if autoPilot.enabled then
    html[#html+1] = [[<div class="apAlert" style="font-size: 2vh; color: ivory; text-align: center; text-shadow: 0.2vh 0.2vh 1vh black;">
    AUTOPILOT
    </div>]]
    end
    if autoPilot.landingMode then
        html[#html+1] = [[<div class="apAlert" style="font-size: 2vh; color: ivory; text-align: center; text-shadow: 0.2vh 0.2vh 1vh black;">
        PARKING MODE
        </div>]]
    end
    if gCache.safetyThrottle then
        html[#html+1] = [[<div class="apAlert" style="font-size: 2vh; color: ivory; text-align: center; text-shadow: 0.2vh 0.2vh 1vh black;">
        BURN PROTECTION
        </div>]]
    end

    if inputs.brake > 0 then
        html[#html+1] = [[<div class="brakeAlert" style="font-size: 2vh; color: orangered; text-align: center; text-shadow: 0.2vh 0.2vh 1vh black;">
        BRAKE
        </div>]]
    end

    local collisionStatus = false
    if gCache.collision ~= nil then    
        local bDist2 = utils.round(bDist*1.2)
        local vSpeed = constructData.vertSpeed*3.6

        --local vRatio = (math.abs(vSpeed))/(constructData.constructSpeed*3.6)
            if gCache.collision.hasAtmosphere then
                local atmoColDist2 = utils.round(vector.dist(constructData.body.center,constructData.constructPosition)-(gCache.collision.atmoRadius))
                if bDist2 > atmoColDist2 and atmoColDist2 > 0 and vSpeed < 0 and constructData.constructSpeed > constructData.burnSpeed then
                    collisionStatus = true
                end
            else
                local moonColDist = utils.round(vector.dist(constructData.body.center,constructData.constructPosition)-(gCache.collision.radius*1.1))
                if bDist2 > moonColDist and moonColDist > 0 and vSpeed < 0 then
                    collisionStatus = true
                end
            end
            if collisionStatus then
                html[#html+1] = [[<div class="collision" style="font-size: 1.5vh; color: ivory; text-align: center; text-shadow: 0.2vh 0.2vh 1vh black;">
                Collision Alert : ]]..tostring(gCache.collision.name)..[[
                </div>]]
            end
            if autoPilot.userConfig.throttleBurnProtection then --Atmo throttle overspeed protection
                if not autoPilot.enabled and not autoPilot.landingMode and not gCache.orbitalHold then
                    if collisionStatus then
                        gCache.safetyThrottle = true
                        if controlMode() == 'cruise' then
                            swapControl()
                        end
                        if cPitch < 5 then
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                        end
                    end
                    if gCache.safetyThrottle == true then
                        if collisionStatus then
                        gCache.collisionBrake = true
                            brakeCtrl = 30
                            inputs.brake = 1
                        end
                    end
                end
            end
    end
    if not collisionStatus and gCache.collisionBrake then
        brakeCtrl = 31
        gCache.collisionBrake = false
        if not gCache.brakeState then
            inputs.brake = 0
        end
    end
    html[#html+1] = '<style>' .. HUD.staticCSS.css .. '></style>'

    local targetPoint = library.getPointOnScreen(getXYZ(autoPilot.target)) -- Target
    local reticle1 = getReticle(constructData.worldForward*constructData.constructSpeed)
    local point1 = library.getPointOnScreen(reticle1) -- Forward Vector
    local vector2 = vectorRotated(targetAngularVelocity,constructData.worldForward)
    local reticle2 = getReticle(vector2*10)
    local point2 = library.getPointOnScreen(reticle2) --ManeuverNode(AP/player Input... where its attempting to point the nose.) --Currently just the current TAV
    local reticle3 = getReticle(constructData.worldVelocityDirection*constructData.constructSpeed)
    local point3 = library.getPointOnScreen(reticle3) --Prograde
    local reticle4 = getReticle(-(constructData.worldVelocityDirection)*constructData.constructSpeed)
    local point4 = library.getPointOnScreen(reticle4) --ManeuverNode - predicted motion
    local vector5 = vectorRotated((circleNormal(autoPilot.target)),constructData.worldForward)
    local reticle5 = getReticle(vector5*10)
    local point5 = library.getPointOnScreen(reticle5) --Retrograde
    
    for _,planet in pairs(atlas[systemId]) do
        local planetTrgt = library.getPointOnScreen(getXYZ(planet.center))
        local scale = utils.clamp(utils.round((vector.dist(planet.center,constructData.constructPosition))/200000),10,500)
        local scaleMap = (math.abs(utils.map(scale, 10, 500, 0.3, 2) - 2.4))
        local planetType = HUD.staticSVG.planetsIcon
        if constructData.body.name ~= planet.name or (constructData.body.name ~= planet.name and vector.dist(constructData.body.center, constructData.constructPosition) > 100000)  then
            if planet.type == 'Planet' and (gCache.arMode == 'planets' or gCache.arMode == 'both') then
                planetType = HUD.staticSVG.planetsIcon
                html[#html+1] = [[<div class="planets" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh) scale(]]..scaleMap..[[)">]]..planetType..[[</div>]]
                html[#html+1] = [[<div class="ptext" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh); font-size: 1vhx; text-shadow: 4px 4px 5px maroon;">]]..tostring(planet.name)..[[</div>]]
            elseif planet.type == 'Moon' and (gCache.arMode == 'moons' or gCache.arMode == 'both') then
                planetType = HUD.staticSVG.moonsIcon
                html[#html+1] = [[<div class="planets" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh) scale(]]..scaleMap..[[)">]]..planetType..[[</div>]]
                html[#html+1] = [[<div class="mtext" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh); font-size: 1vh; text-shadow: 4px 4px 5px midnightblue;">]]..tostring(planet.name)..[[</div>]]
            end
        end  
        --system.print(tostring(scale)..' scale')
        --system.print(tostring(scaleMap)..' Map')
    end

    html[#html+1] = [[<div class="dot" style="transform:translate(]]..(targetPoint[1]*100)..[[vw,]]..(targetPoint[2]*100)..[[vh)">]]..HUD.staticSVG.targetReticle..[[</div>]]
    html[#html+1] = [[<div class="dottext" style="transform:translate(]]..(targetPoint[1]*100)..[[vw,]]..(targetPoint[2]*100)..[[vh)">]]..HUD.dynamicSVG.targetReticle2..[[</div>]]
  
    html[#html+1] = [[<div class="dot" style="transform:translate(]]..(point1[1]*100)..[[vw,]]..(point1[2]*100)..[[vh)">]]..HUD.staticSVG.crosshair..[[</div>]]
    html[#html+1] = [[<div class="dot" style="transform:translate(]]..(point2[1]*100)..[[vw,]]..(point2[2]*100)..[[vh)">]]..HUD.staticSVG.maneuverNode..[[</div>]]
    html[#html+1] = [[<div class="dot" style="transform:translate(]]..(point3[1]*100)..[[vw,]]..(point3[2]*100)..[[vh)">]]..HUD.staticSVG.progradeReticle..[[</div>]]
    html[#html+1] = [[<div class="dot" style="transform:translate(]]..(point4[1]*100)..[[vw,]]..(point4[2]*100)..[[vh)">]]..HUD.staticSVG.retrogradeReticle..[[</div>]]
    html[#html+1] = [[<div class="dot" style="transform:translate(]]..((getSafeZoneBorder().arBorder)[1]*100)..[[vw,]]..((getSafeZoneBorder().arBorder)[2]*100)..[[vh); font-size: 1vh">]]..HUD.staticSVG.skull..printDistance(getSafeZoneBorder().borderDist, true)..[[</div>]]
    --html[#html+1] = [[<div class="dot" style="transform:translate(]]..((getSafeZoneBorder().arBorder)[1]*100)..[[vw,]]..((getSafeZoneBorder().arBorder)[2]*100)..[[vh)">]]..tostring(getSafeZoneBorder().borderDist)..[[</div>]]
   
    getSafeZoneBorder()
    
    return table.concat(html)
end