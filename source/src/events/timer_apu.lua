function onTimerAPU()
    local gCache = globals
    local aCache = axis
    local autoPilot = AutoPilot
    local aggData = aggData
    local constructData = constructData
    gCache.collision, gCache.farSide, gCache.nearSide = castIntersections()
    gCache.collisionAlert = false
    dynamicSVG()
    local curAltitude = constructData.altitude
    local curTargAlt = autoPilot.targetAltitude
    --temporary override until fix found.
   
    if autoPilot.landingMode then
        unit.deployLandingGears()
    end

--[[
    if gCache.collision ~= nil then
        if gCache.collision.bodyId ~= targetBody.bodyId then
            if gCache.collision.hasAtmosphere then
                local atmoColDist = vector.dist(gCache.collision.center,constructData.constructPosition)-(gCache.collision.atmoRadius*1.05)
                if constructData.brakes.distance*1.4 >= atmoColDist and getAltitude() > gCache.collision.atmoAltitude*1.05 then
                    gCache.collisionAlert = true
                end
            else
                local moonColDist = vector.dist(gCache.collision.center,constructData.constructPosition)-(gCache.collision.radius*1.5)
                if constructData.brakes.distance*1.4 >= moonColDist and getAltitude() > gCache.collision.radius*1.2 then
                    gCache.collisionAlert = true
                end
            end
        end
    end
]]


    if gCache.followMode then
        local shipDist = vector.dist(constructData.constructPosition,playerData.playerPosition)
        local playerSpeed = playerData.playerVelocity:len()*3.6
        local shipSpd = 20 + playerSpeed - (20 - math.min(shipDist-50,20))
        if playerSpeed == 0 then
            shipSpd = 20
        end
        if shipDist > 200 then
            gCache.followReposition = true
            Nav.axisCommandManager:setTargetGroundAltitude(40)
            if autoPilot.landingMode then
                autoPilot:toggleLandingMode(false)
            end
        end

        if gCache.followReposition then
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(shipSpd))
            if constructData.constructSpeed*3.6 > shipSpd+10 then
                inputs.brake = 1
            else
                inputs.brake = 0
            end
        end

        if gCache.followReposition == true and shipDist < 50 and playerSpeed < 30 then
            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(0))
            if not autoPilot.landingMode then
                autoPilot:toggleLandingMode(true)
            end
            gCache.followReposition = false
        end
    end

    if gCache.safetyThrottle and (system.getMouseWheel() ~= 0 or gCache.orbitalHold) then
        if not inputs.manualBrake then
            inputs.brake = 0
        end
        gCache.safetyThrottle = false
    end

    if autoPilot.enabled then
        inputs.brake = 0
        Nav.axisCommandManager:setTargetGroundAltitude(40)
    end
   
    if constructData.atmoDensity > 0 then
        gCache.inAtmo = true else
        gCache.inAtmo = false
    end

    if autoPilot.userConfig.throttleBurnProtection then --Atmo throttle overspeed protection
        if not autoPilot.enabled and not autoPilot.landingMode and not gCache.orbitalHold and not inputs.manualBrake then
            local cPitch = utils.round(constructData.rpy.pitch)
            if constructData.atmoDensity >= 0.05 or (gCache.inAtmo and constructData.vertSpeed*3.6 < -100) then
                if constructData.constructSpeed*3.6 > (constructData.burnSpeed*3.6) or gCache.safetyThrottle then
                    gCache.safetyThrottle = true
                    if controlMode() == 'cruise' then
                        swapControl()
                    end
                    if constructData.atmoDensity < 0.05 and cPitch > 5 then
                    else
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle((constructData.burnSpeed*3.6)-100))
                    end
                end
                if gCache.safetyThrottle then
                    if constructData.constructSpeed*3.6 > (constructData.burnSpeed*3.6)-50 then
                        brakeCtrl = 32
                        inputs.brake = 1
                    else
                        brakeCtrl = 33
                        inputs.brake = 0
                    end
                end
            end
        else
            gCache.safetyThrottle = false
        end
    end
    
    if links.shield ~= nil and autoPilot.userConfig.shieldManage == true then
		--system.print(shield.getResistancesCooldown())
		local srp = links.shield.getResistancesPool()
		local csr = links.shield.getResistances() --CurrentShieldResistances
		local rcd = links.shield.getResistancesCooldown() --ResistanceCooldown
		local shp = links.shield.getShieldHitpoints() --shield hitpoints
        local mshp = links.shield.getMaxShieldHitpoints()
        local sHealth = ((shp/mshp)*100)

		if links.shield.getStressHitpointsRaw() == 0 then
    		srp = srp / 4
    		-- Set shield resistances evenly.
    		-- Returns 0 on fail and 1 on success
			if (csr[1] == srp and csr[2] == srp and csr[3] == srp and csr[4] == srp) or rcd ~= 0 then --if resistances are already balanced, dont waste the resistance timer.
			--do nothing
			else
    		links.shield.setResistances(srp,srp,srp,srp) --if they need to be balanced and timer is up, do so.
			end
		else
    		-- Get damage type ratios out of 100%
    		local srr = links.shield.getStressRatioRaw()
    		-- Set shield resistances based on damage type percentages
			if (csr[1] == (srp*srr[1]) and csr[2] == (srp*srr[2]) and csr[3] == (srp*srr[3]) and csr[4] == (srp*srr[4])) or rcd ~= 0 then -- If ratio hasent change, or timer is not up, dont waste the resistance change timer.
		     --do nothing
			else --If stress ratio has changed, and the reset timer is up, update resistances.
    			links.shield.setResistances(srp*srr[1],srp*srr[2],srp*srr[3],srp*srr[4])
			end
		end

		if shp == 0 and links.shield.getVentingCooldown() == 0 then --vent if shield goes down and venting is available
			links.shield.startVenting()
		end
		
		if constructData.pvpZone == true and links.shield.isActive() == false then
			links.shield.activate()
		elseif constructData.pvpZone == false and links.shield.isActive() == true then
			links.shield.deactivate()
		end		
	end             

    if not autoPilot.enabled then
        gCache.apMode = 'Off'
    end
 

    if inputs.pitch ~= 0 and not autoPilot.enabled then 
        gCache.holdAltitude = curAltitude
    end
    
    if links.antigrav ~= nil then
        if aggData.aggState == true and autoPilot.userConfig.autoAGG == true and autoPilot.targetLoc == 'surface' then
            gCache.aggAP = true
        else
            gCache.aggAP = false
        end
    else 
        gCache.aggAP = false
    end

    
    --[[local inBubble = false
    if aggData ~= nil then
        if aggData.aggState == 1 then
            if curAltitude > aggData.aggAltitude-100 and curAltitude < aggData.aggAltitude+100 then
                inBubble = true
            end
            gCache.aggAP = true
        else
            gCache.aggAP = false
            inBubble = false
        end
    end]]



    if autoPilot.enabled or gCache.altitudeHold then --TODO customizable max speed / or burnSpeed
        altHold()
                    --===Maybe clamp throttle to burn speed for alt hold so user doesnt accidently over throttle??
        --SpdControl = '1'
        --Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(1000))
        --if constructData.constructSpeed*3.6 > (constructData.burnSpeed*3.6)-200 then
         --   inputs.brake = 1
        --end
     end

    --if gCache.altitudeHold then
    --    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle())
    --end
    if not gCache.orbitalHold or gCache.apMode ~= 'Orbit' then
        gCache.inOrbit = false
    end

    if gCache.orbitalHold or gCache.apMode == 'Orbit' then
        local atmoAlt = constructData.body.atmoRadius - constructData.body.radius
        local surfaceAlt = constructData.body.surfaceMaxAltitude
        local orbitAltT = constructData.orbitFocus.orbitAltTarget
        local orbitSpd = constructData.orbitFocus.orbitSpeed * 3.6
        local apo = constructData.orbitalParameters.apoapsis.altitude
        local peri = constructData.orbitalParameters.periapsis.altitude
        local tApo = constructData.orbitalParameters.timeToApoapsis
        local tPer = constructData.orbitalParameters.timeToPeriapsis
        brakeCtrl = 0
        inputs.brake = 0

        if gCache.apMode == 'Orbit' then
            if math.abs(getVelocityTargetAngle()) > 2 then
                brakeCtrl = 0.1
                inputs.brake = 1
            end
        end

        if not gCache.inAtmo and curAltitude >= gCache.targetOrbitAlt and not gCache.inOrbit then
            if constructData.constructSpeed*3.6 >= orbitSpd then
                brakeCtrl = 1
                inputs.brake = 1
            end
        end
        if not gCache.inOrbit and constructData.vertSpeed*3.6 < -400 then
            brakeCtrl = 2
            inputs.brake = 1
        end

        if apo > surfaceAlt and peri > surfaceAlt then
            gCache.inOrbit = true
        else
            gCache.inOrbit = false
        end

        if controlMode() == 'cruise' then
            swapControl()
        end

        if gCache.inOrbit then
            if apo < gCache.targetOrbitAlt-100 then
                if tPer < 5 then
                    apoUp = true
                end
            end
            --[[
            if peri < gCache.targetOrbitAlt-100 and periUp == true then
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 1)
            else
                periUp = false
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
            end
            ]]

            if (apo < gCache.targetOrbitAlt-100 and apoUp == true) or (peri < gCache.targetOrbitAlt-100 and periUp == true) then
                SpdControl = '2'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0.1)
            else
                periUp = false
                apoUp = false
                SpdControl = '3'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
            end
            if apo > gCache.targetOrbitAlt+100 then
                if tPer < 5 then
                    lastPeri = peri
                    apoDown = true
                end
            end
            if apoDown then
                if lastPeri > peri + 50 then
                    apoDown = false
                end
            end
            if apo > gCache.targetOrbitAlt+100 and apoDown == true then
                brakeCtrl = 'apoDwn'
                inputs.brake = 1
            else
                lastPeri = peri+1000
                apoDown = false
            end

            if peri < gCache.targetOrbitAlt-100 then
                if tApo < 5 then
                    periUp = true
                end
            end
            if peri > gCache.targetOrbitAlt+100 then
                if tApo < 5 then
                   lastApo = apo
                    periDown = true
                end
            end

            if periDown then
                if lastApo > apo + 50 then
                    periDown = false
                end
            end

            if peri > gCache.targetOrbitAlt+100 and periDown == true then
                brakeCtrl = 3
                inputs.brake = 1
            else
                lastApo = apo+1000
                periDown = false
            end

        else
            local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
            local aligned = false
            if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) then
                aligned = true
            end 
            if unit.getAtmosphereDensity() > 0.05 then
                SpdControl = '4'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle())
            else

                --if curAltitude > gCache.targetOrbitAlt+500 and orbitAltT < 0 then
                --   if controlMode() == 'travel' then
                --       swapControl()
                --   end
                --    Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, orbitSpeed*3.6)
                if orbitAltT > gCache.targetOrbitAlt-100 and curAltitude < gCache.targetOrbitAlt-5 then
                    SpdControl = '5'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)

                elseif orbitAltT < (gCache.targetOrbitAlt-100)  then
                    SpdControl = '6'
                    if aligned or constructData.vertSpeed*3.6 < 0 then
                        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(orbitSpd))
                    else
                        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0.1)
                    end
            

                --elseif orbitAltT > (gCache.targetOrbitAlt-400) then
                   -- if controlMode() == 'travel' then
                    --    swapControl()
                    --end
                   -- Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, (orbitSpd))
                else
                   -- Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, (orbitSpd))
                   SpdControl = '7' 
                   Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(orbitSpd))
                end
            end
        end
    end

    if (autoPilot.enabled or gCache.altitudeHold or gCache.orbitalHold) and gCache.inAtmo and getVelocityAngle() > autoPilot.userConfig.wingStallAngle then
        gCache.stallProtect = true
    else
        gCache.stallProtect = false
    end
    
    if autoPilot.enabled then
        if inputs.brakeLock then
            inputs.brakeLock = false
        end
        local body = constructData.body
        local targetBody = autoPilot.targetBody
        local projDist = projectedDistance(autoPilot.target)
        if gCache.safetyThrottle == true then
            gCache.safetyThrottle = false
        end
        setTargetOrbitAlt()
        --[[if gCache.waitForBubble then
            if controlMode() == 'travel' then
                swapControl()
            end
        elseif SpdControl ~= '9.4' then
            if controlMode() == 'cruise' then
                swapControl()
            end
        end]]
        local behindPlanet = false
        if not autoPilot.targetIsLastPoint then
            if autoPilot.targetLoc == 'space' then
                if vector.dist(autoPilot.target,constructData.constructPosition) < 10000 then
                    autoPilot.onPointReached()
                end
            end
            if autoPilot.targetLoc == 'surface' then
                if sameBody and projDist < 1000 then
                    autoPilot.onPointReached()
                end
            end
        end
        
        if gCache.apMode ~= 'Orbit' then
        brakeCtrl = 4
        inputs.brake = 0
        end

        if gCache.aggAP then
            gCache.holdAltitude = aggData.aggAltitude
        else
            if body.hasAtmosphere then
                gCache.holdAltitude = math.max(math.max(body.surfaceMaxAltitude+1500,curTargAlt+1000), body.atmoAltitude*0.5)
            else
                gCache.holdAltitude = math.max(body.surfaceMaxAltitude+3000,curTargAlt+1000)
            end
        end

        if targetBody.bodyId ~= body.bodyId and not gCache.spaceCapable then
            print('Ship not space capable, shutting down AP')
            autoPilot:toggleState(false)
        end

        if body.bodyId == targetBody.bodyId then
            sameBody = true
        else
            sameBody = false
        end


        --if gCache.aggAP then
        --    links.antigrav.setTargetAltitude((targetBody.atmoRadius - targetBody.radius)+1000)
        --end

        if not gCache.spaceCapable then
            if not sameBody or curTargAlt > (targetBody.atmoRadius - targetBody.radius) then
            system.print('point on other planet, ship currently set to not space capable.')
            autoPilot:toggleState(false)
            end
        end

        local reEntryTrigger = false
        if gCache.apMode == 'reEntry' then
            reEntryTrigger = true
        end

        if sameBody and autoPilot.targetLoc == 'surface' then
            if getTargetWorldAngle() > 18 then
                behindPlanet = true
            end
        else
            if getTargetWorldAngle() > 80 and vector.dist(body.center,constructData.constructPosition) < body.radius*2 then
                behindPlanet = true
            end
        end




        
        if (math.abs(constructData.forwardSpeed) + math.abs(constructData.lateralSpeed)) < 3 then
            gCache.horizontalStopped = true 
        else
            gCache.horizontalStopped = false
        end
        if not gCache.brakeTrigger then
            if sameBody and gCache.inAtmo and not behindPlanet and not gCache.aggAP and autoPilot.targetLoc == 'surface' or not gCache.spaceCapable then
                gCache.apMode = 'Atmo Travel'
            elseif (not sameBody or autoPilot.targetLoc == 'space') and gCache.inAtmo and gCache.smoothClimb then
                gCache.apMode = 'Transition'
            elseif (((not sameBody or autoPilot.targetLoc == 'space') and not behindPlanet and not gCache.spaceBrakeTrigger) or (sameBody and curAltitude > gCache.targetOrbitAlt+1000 and not gCache.spaceBrakeTrigger) and not aggData.aggBubble) or gCache.apMode == 'standby' then
                gCache.apMode = 'Transfer'
                gCache.orbitLock = false
            elseif gCache.aggAP and aggData.aggBubble then
                gCache.spaceBrakeTrigger = false
                gCache.apMode = 'agg'
            elseif (not gCache.inAtmo and (constructData.brakes.distance*1.5 >= projDist) and ((curAltitude < gCache.targetOrbitAlt+5000 and sameBody) or reEntryTrigger or (sameBody and gCache.inOrbit))) and not gCache.aggAP and body.hasAtmosphere and autoPilot.targetLoc == 'surface' then --TODO do a check for if moon/asteroid or space points later and have different reaction since you cant reenter.
                gCache.orbitLock = false
                gCache.apMode = 'reEntry'
            elseif ((behindPlanet and sameBody and curAltitude < gCache.targetOrbitAlt+2000) or (behindPlanet and not sameBody) or gCache.orbitLock) or (sameBody and curAltitude < gCache.targetOrbitAlt+2000 and not targetBody.hasAtmosphere)and not gCache.aggAP and gCache.spaceCapable then
                gCache.orbitLock = true
                gCache.apMode = 'Orbit'
            elseif gCache.spaceBrakeTrigger and not gCache.inAtmo then
                gCache.apMode = 'Space Braking'
            end
        end
        
        if links.antigrav ~= nil then
            if aggData.aggState == true and autoPilot.targetLoc == 'surface' then
                --[[if body.name ~= targetBody.name and inAtmo and inBubble then
                    if aggData.aggTarget ~= body.atmoAltitude+1000 then
                        inks.antigrav.setTargetAltitude( body.atmoAltitude+1000 )
                    end
                end]]
                --[[if body.name ~= targetBody.name and inAtmo and not inBubble then
                    if curAltitude <= 1000 then
                        if aggData.aggTarget ~= 1000 then 
                            links.antigrav.setTargetAltitude( 1000 )
                        end
                    elseif curAltitude > 1000 then
                        if aggData.aggTarget ~= curAltitude then 
                        links.antigrav.setTargetAltitude( curAltitude )
                        end
                    end
                end]]
                --if body.name ~= targetBody.name then
                    if targetBody.hasAtmosphere and not aggData.aggBubble or not sameBody then
                        if aggData.aggTarget ~= targetBody.atmoAltitude then 
                            links.antigrav.setTargetAltitude( targetBody.atmoAltitude )
                        end
                    elseif sameBody and aggData.aggBubble then
                        if curTargAlt == 0 then
                            if aggData.aggTarget ~= math.max(math.max(curTargAlt+500,1000),targetBody.surfaceMaxAltitude) then 
                                links.antigrav.setTargetAltitude( math.max(math.max(curTargAlt+500,1000),targetBody.surfaceMaxAltitude) )
                            end
                        else
                            if aggData.aggTarget ~= math.max(curTargAlt+500,1000) then
                                links.antigrav.setTargetAltitude( math.max(curTargAlt+500,1000) )
                            end
                        end
                    end
                --end
            end
        end


        if gCache.apMode == 'agg' then
            local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
            local aligned = false
            if (tavCheck.x < 0.005 and  tavCheck.y < 0.005 and tavCheck.z < 0.005) or constructData.constructSpeed*3.6 < 4000 or (constructData.gravity > 0.5 and not sameBody) then
                aligned = true
            end 
            local wTargetAngle = getTargetWorldAngle()
            local orbitSpd = constructData.orbitFocus.orbitSpeed*3.6
            local aggDist = ((vector.dist(targetBody.center,constructData.constructPosition) - targetBody.radius) - aggData.aggAltitude)
            --[[if aggData.aggBubble and math.abs(constructData.vertSpeed*3.6) > 25 then
                brakeCtrl = 5
                inputs.brake = 1
            end]]
           -- SpdControl = 'agg waiting'
            if wTargetAngle >= 0.5 and wTargetAngle < 5 and aligned then
                --gCache.spaceBrakeTrigger = false
                SpdControl = 'agg 1'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(300))
               -- if constructData.constructSpeed*3.6 > 320 then
                --    brakeCtrl = 6
                --    inputs.brake = 1
               -- end
            end  
            
            if wTargetAngle >= 5 and aligned then
                --gCache.spaceBrakeTrigger = false
                SpdControl = 'agg 2'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(orbitSpd))
            end         
        end

        local planetDist = vector.dist(constructData.constructPosition, targetBody.center)
        if targetBody.hasAtmosphere then
            planetDist = utils.round(planetDist - (targetBody.atmoRadius*1.05))
        else
            planetDist = planetDist - (targetBody.radius*1.5)
        end

        if gCache.apMode == 'Transfer' or gCache.apMode == 'Space Braking' then 
            local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
            local aligned = false
            if autoPilot.targetLoc == 'surface' then
                if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) or constructData.constructSpeed*3.6 < 4000 or (constructData.gravity > 0.5 and not sameBody and constructData.constructSpeed*3.6 < autoPilot.maxSpaceSpeed) then
                    aligned = true
                end
            end
            if autoPilot.targetLoc == 'space' then
                if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) or constructData.constructSpeed*3.6 < 500 or (constructData.gravity > 0.5 and not sameBody and constructData.constructSpeed*3.6 < autoPilot.maxSpaceSpeed) then
                    aligned = true
                end
            end

            if gCache.aggAP and autoPilot.targetLoc ~= 'space' then
                local aggDist = ((vector.dist(targetBody.center,constructData.constructPosition) - targetBody.radius) - aggData.aggTarget)
                if gCache.aggAP and constructData.brakes.distance*1.5 >= aggDist then
                    gCache.spaceBrakeTrigger = true
                    brakeCtrl = 9
                    inputs.brake = 1
                end
                if gCache.aggAP and sameBody and curAltitude <= aggData.aggTarget+100 and not aggData.aggBubble then
                    gCache.waitForBubble = true
                    SpdControl = 'agg 5'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                    brakeCtrl = 10
                    inputs.brake = 1
                else
                    gCache.waitForBubble = false
                end
            end

            if (autoPilot.targetLoc == 'surface' and constructData.brakes.distance*1.4 >= curAltitude - gCache.targetOrbitAlt and sameBody and gCache.apMode ~= 'Landing' and constructData.constructSpeed*3.6 > 1000) or (autoPilot.targetLoc == 'surface' and constructData.brakes.distance*1.4 >= planetDist and not sameBody) then --TODO if target is on planet, or if mmon or space target. etc.
                gCache.spaceBrakeTrigger = true
                brakeCtrl = 11
                inputs.brake = 1
            end
            
            if autoPilot.targetLoc == 'space' and constructData.brakes.distance*1.4 >= vector.dist(autoPilot.target,constructData.constructPosition)-1000 then
                gCache.spaceBrakeTrigger = true
                if vector.dist(autoPilot.target,constructData.constructPosition) < 1000 then
                    if constructData.constructSpeed*3.6 > 110 then
                    brakeCtrl = 11.1
                    inputs.brake = 1
                    end
                else
                    brakeCtrl = 11.2
                    inputs.brake = 1
                end
            end

            if getSpaceVelocityTargetAngle() > 50 and gCache.apMode ~= 'Space Braking' and not gCache.inAtmo then
                brakeCtrl = 12
                inputs.brake = 1
            end
           
            if not gCache.spaceBrakeTrigger then

                if constructData.constructSpeed*3.6 < autoPilot.maxSpaceSpeed and aligned or constructData.constructSpeed*3.6 < 3000 then
                    SpdControl = '8'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(autoPilot.maxSpaceSpeed))
                elseif constructData.constructSpeed*3.6 < autoPilot.maxSpaceSpeed then
                    SpdControl = '8.1'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0.3)
                else
                    SpdControl = '8.1.1'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                end
                if getSpaceVelocityTargetAngle() > 0.05 and aligned and constructData.constructSpeed*3.6 >= autoPilot.maxSpaceSpeed then
                    SpdControl = '8.2'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, utils.clamp((getSpaceVelocityTargetAngle()*0.1)-0.01,0,1))
                end
                if constructData.atmoDensity > 0.05 then
                    SpdControl = '8.3'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle())
                end
            else
                if autoPilot.targetLoc == 'surface' then
                    if not gCache.aggAP then
                        if getTargetWorldAngle() > 0.5 and constructData.forwardSpeed*3.6 < 500 and aligned then
                            SpdControl = '9'
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(500,constructData.forwardSpeed))
                        else
                            SpdControl = '9.1'
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                        end
                    else
                        if getTargetWorldAngle() > 0.5 and constructData.forwardSpeed*3.6 < 500 and aligned and curAltitude > aggData.aggTarget+200 then
                            SpdControl = '9.2'
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(500,constructData.forwardSpeed))
                        else
                            SpdControl = '9.3'
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                        end
                    end
                else
                    if not gCache.spaceBrakeTrigger then
                        SpdControl = '9.4'
                        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(autoPilot.maxSpaceSpeed))
                    else
                        SpdControl = '9.5'
                        if getSpaceVelocityTargetAngle() > 10 then
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(autoPilot.maxSpaceSpeed))
                            brakeCtrl = 12.1
                            inputs.brake = 1
                        else
                            Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(100,constructData.forwardSpeed))
                        end
                    end
                       
                    --[[if controlMode() == 'travel' then
                        swapControl()
                    end
                    SpdControl = '9.4'
                    local brakeSpeed = brakeSpeed
                    if brakeSpeed == nil then
                        brakeSpeed = 0
                    end
                    if brakeCtrl == 11.1 then
                        brakeSpeed = constructData.constructSpeed*3.6
                    end
                    
                    Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal,math.max(utils.round(vector.dist(autoPilot.target,constructData.constructPosition)/8),100))
                    if inputs.brake == 1 then
                        Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, 0 )
                        
                    end]]
                        
                    --[[if getSpaceVelocityTargetAngle() > 0.05 then
                        if controlMode() == 'travel' then
                            swapControl()
                        end
                        SpdControl = '9.4'
                        Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal,0)
                        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, math.max(getThrottle(math.min(gCache.maxSpaceSpeed,vector.dist(autoPilot.target,constructData.constructPosition)/5),constructData.forwardSpeed),0.1))
                        if getSpaceVelocityTargetAngle() > 50 then
                            inputs.brake = 1
                        end
                    else
                        SpdControl = '9.5'
                        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
                    end]]
                end
            end
                --if gCache.spaceBrakeTrigger then
                --    if constructData.vertSpeed < -200 then
                 --       Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle((constructData.maxSpeed*3.6)-1))
                 --   end
                --end
            
        end

        if (autoPilot.targetLoc == 'surface' and constructData.brakes.distance*1.4 >= planetDist and not sameBody) and constructData.constructSpeed*3.6 * 1000 then --TODO if target is on planet, or if mmon or space target. etc.
            gCache.spaceBrakeTrigger = true
            brakeCtrl = 11.5
            inputs.brake = 1
        end

        --if gCache.apMode == 'Orbit' and sameBody or gCache.apMode == 'reEntry' or gCache.apMode == 'Atmo Travel' then
        if (sameBody and gCache.inAtmo and gCache.apMode ~= 'Orbit' and gCache.apMode ~= 'Landing' and autoPilot.targetLoc ~= 'space' ) or gCache.apMode == 'reEntry' then  
            if (projDist < 5000 and not gCache.brakeTrigger) then
                SpdControl = '10'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(math.min(utils.round(projDist/2),500),constructData.forwardSpeed))
                if constructData.forwardSpeed*3.6 > math.min(utils.round(projDist/2),500)+100 and gCache.apMode == 'reEntry' then
                    brakeCtrl = 13
                    inputs.brake = 1 
                end
            end        
            if gCache.apMode == 'reEntry' then
                if projDist < 300 then
                gCache.brakeTrigger = true
                end
            end
            if gCache.inAtmo and not autoPilot.waitForBubble then
                SpdControl = '11'
                    Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle((constructData.burnSpeed*3.6)-150))
                    if math.abs(getVelocityTargetAngle()) > 5 then
                        brakeCtrl = 13.1
                        inputs.brake = 1
                    end

                    if constructData.constructSpeed*3.6 > (constructData.burnSpeed*3.6)-100 then
                        brakeCtrl = 14
                        inputs.brake = 1
                    end 
                    if constructData.brakes.distance*1.5 >= projDist or projDist < 300 then
                        gCache.brakeTrigger = true
                    end
            end
        end

        if gCache.apMode == 'reEntry' then
            if getTargetWorldAngle() > 1 then
                if constructData.vertSpeed*3.6 < -200 then
                    SpdControl = '12'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle(1000,constructData.forwardSpeed))
                else
                    SpdControl = '13'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, getThrottle())
                end
                if constructData.constructSpeed*3.6 >= (constructData.burnSpeed*3.6)-300 then
                    brakeCtrl = 15
                    inputs.brake = 1 
                end
            else
                gCache.brakeTrigger = true
            end
        end

        if gCache.apMode == 'Orbit' and (sameBody and not targetBody.hasAtmosphere or gCache.aggAP) then

            if math.abs(getVelocityTargetAngle()) > 5 then
                brakeCtrl = 15.1
                inputs.brake = 1
            end

            if (constructData.brakes.distance*1.4 >= (projDist)) then
                gCache.brakeTrigger = true
            end
        end
 
        if (gCache.apMode == 'reEntry' or (sameBody and curAltitude < gCache.targetOrbitAlt + 2000)) and autoPilot.targetLoc ~= 'space' then
            if gCache.brakeTrigger then
                gCache.orbitLock = false
                if projDist > 1000 then
                    gCache.brakeTrigger = false
                end
                gCache.apMode = 'Landing'
                if gCache.lastProjectedDistance > projDist then
                    gCache.lastProjectedDistance = projDist
                end
                SpdControl = '14'
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
			
                if  ((not gCache.horizontalStopped) and (constructData.brakes.distance*1.4 >= (gCache.lastProjectedDistance - 150))) or (constructData.vertSpeed*3.6 < -1000) then
                    brakeCtrl = 16
                    inputs.brake = 1
                end
                if curTargAlt == 0 or autoPilot.target == targetBody.center then
                    curTargAlt = targetBody.surfaceMaxAltitude
                end
                if links.antigrav ~= nil then
                    if aggData.aggState == true and autoPilot.targetLoc == 'surface' then
                        curTargAlt = aggData.aggAltitude
                    end
                end
                if gCache.horizontalStopped then
                    if (constructData.brakes.distance*3 >= (curAltitude - curTargAlt)+300) or (constructData.vertSpeed*3.6 < -100 and (curAltitude - curTargAlt) < 400) or constructData.constructSpeed*3.6 > 1000 then
                        brakeCtrl = 17
                        inputs.brake = 1 
                    end
                    if curAltitude < curTargAlt+500 and constructData.vertSpeed*3.6 < -75 then
                        brakeCtrl = 18
                        inputs.brake = 1 
                    end
                end
                if curAltitude <= curTargAlt and constructData.vertSpeed >= 0 then
                    autoPilot:onPointReached()
                end

                if gCache.horizontalStopped and projDist > 300 then --TODO system to make sure you dont over pitch to return to target while braking.
                    gCache.missedTarget = true
                end
            end
        end
        if autoPilot.targetLoc == 'space' then
            if vector.dist(autoPilot.target,constructData.constructPosition) <= 1500 then
                autoPilot:onPointReached()
            end
        end

        if gCache.initTurn then
            SpdControl = 'turn'
            if math.abs(getTargetAngle()) > 90 and constructData.constructSpeed < 30 then
                Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
            else
                gCache.initTurn = false
            end
        end

       
    end


    
    if gCache.waterMode and curAltitude < 0 and gCache.inAtmo then
        if inputs.pitch ~= 0 or gCache.verticalState then
            gCache.waterAlt = curAltitude
        end
        if not gCache.verticalState and not autoPilot.landingMode then
            if (curAltitude < gCache.waterAlt and constructData.vertSpeed*3.6 < 5) or (constructData.vertSpeed*3.6 < -5) then
                gCache.waterState = true
                Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
                Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
                Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
                --Nav.axisCommandManager:setTargetGroundAltitude(gCache.waterAlt)
            else
                gCache.waterState = false
                Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
                --Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, -1.0)
                Nav.axisCommandManager:activateGroundEngineAltitudeStabilization(currentGroundAltitudeStabilization)
                Nav.axisCommandManager:setTargetGroundAltitude(-1)
            end
        else
            Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
            --Nav.axisCommandManager:setTargetGroundAltitude(-1)
        end
    end

    if autoPilot.landingMode then
        --Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
        Nav.axisCommandManager:setTargetSpeedCommand(axisCommandId.longitudinal, 0)
        Nav.axisCommandManager:setThrottleCommand(axisCommandId.longitudinal, 0)
        if constructData.vertSpeed*3.6 < -20 then
            Nav.axisCommandManager:setTargetGroundAltitude(curAltitude)
            Nav.axisCommandManager:activateGroundEngineAltitudeStabilization()
            Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
            Nav.axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0)
        else
            Nav.axisCommandManager:resetCommand(axisCommandId.vertical)
            --Nav.axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, -1.0)
            Nav.axisCommandManager:deactivateGroundEngineAltitudeStabilization()
            Nav.axisCommandManager:setTargetGroundAltitude(-1)
        end
        inputs.brake = 1
    end
     
    if inputs.brakeLock then
        inputs.brake = 1
    end
end