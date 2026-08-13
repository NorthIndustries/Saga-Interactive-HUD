--[[
    Command List                   Description                                   Usage Sample (commands not case sensitive)          
    /mainMenu                   -- toggle the main menu on and off              /mainMenu
    /scale                      -- set the hud scale                            /scale 100
    /addpos                     -- add a pos to the route                       /goto ::pos{0,2,8.6408,80.3893,22354.4102}
    /goto                       -- set target to temp point                     /goto ::pos{0,2,8.6408,80.3893,22354.4102}
    /convert                    -- converts a POS to world coords               /convert ::pos{0,2,8.6408,80.3893,22354.4102}
    /debug                      -- toggles debug on and off                     /debug
    /setMaxSpaceSpeed /setMSP   -- set Max Space Speed in km/h                  /setMSP 20000
    /setMaxPitch /setMP         -- set Max Pitch Degree                         /setMP 45
    /setMaxRoll /setMR          --  set Max Roll Degree                         /setMR 35
    /shield                     --enable or disable auto shield management      /shield
    /space                      --toggle if ship is space capable               /space
    /setHover                   --set hover height when out of parking mode     /setHover 20
    /atp                        -- enable or disable atmo Auto throttle         /atp
                                    protection. prevents accelerating
                                    past atmo burn speed
    /alt /altitude              --set specific altitude hold level. pressing    /alt 3000
                                    any movement keys after entering this will
                                    override this to your current altitude.
    /orbitAlt                   --set TargetOrbitAlt                            /orbitAlt 10000
    /radar                      --Toggle Radar Widget                           /radar
    /radarbox                   --Toggle radar hud boxes                        /radarbox
    /freeze                     --freeze player for remote use                  /freeze
    /unit
    /aggAlt                     --set Agg Altitude                              /aggAlt 5000
    /agg                        --Toggle agg on/off                             /agg

]]


function onInput(text)
    local gCache = globals
    local autoPilot = AutoPilot
    local _hud = HUD
	local inputParts = split(text, ' ')
	local action = inputParts[1]:lower()

    if action:sub(1, 1) ~= '/' then
        if _hud.Config.mainMenuVisible then
            local menuHoveredEntity = Widgets.mainMenu.optionMenu:getHoveredEntry()
            if menuHoveredEntity ~= nil and menuHoveredEntity.actions ~= nil and menuHoveredEntity.actions.input ~= nil then
                if menuHoveredEntity.actions.input.filter ~= nil then text = menuHoveredEntity.actions.input.filter(text) end
                menuHoveredEntity.actions.input.func(text, menuHoveredEntity.actions.input.arg)
            end
        end
    else

        if action == '/togglemenu' or action == '/mainmenu' then
            _hud.toggleMainMenu()
        end

        if action == '/scale' or action == '/setscale' then
            Config:setValue(configDatabankMap.hudScale, tonumber(inputParts[2]) / 100)
        end
        
        if action == '/addpos' then
            if #inputParts < 2 then
                print('No target supplied')
            elseif RouteDatabase.currentEditId == nil then
                print('You must have a route open in the Main Menu before using this command')
            else
                addCustomPos(inputParts[2])
            end
        end

        if action == '/goto' then
            if #inputParts < 2 then
                print('No target supplied')
                return
            end
            local target = convertToWorldCoordinates(inputParts[2])
            if target == nil then
                print('Invalid ::pos{...} string')
            else
                autoPilot:setTarget(target)
                resetAP()
                if autoPilot.targetAltitude == 0 or autoPilot.target == autoPilot.targetBody.center then
                    curTargAlt = autoPilot.targetBody.surfaceMaxAltitude
                end
                system.print([[Target Set to ]]..inputParts[2]..[[ near ]]..autoPilot.targetBody.name..[[ ]]..autoPilot.targetLoc..[[ at ]]..autoPilot.targetAltitude..[[ m ]])
            end
        end

        if action == '/convert' then
            if tostring(inputParts[2]) == nil then
            else
            system.print(tostring(convertToWorldCoordinates(inputParts[2])))
            end
        end

        if action == '/debug' then
            gCache.debug = not gCache.debug
        end

        if action == '/setmaxspacespeed' or action == '/setmsp' then
            if tonumber(inputParts[2]) == nil then
            else
                Config:setValue(configDatabankMap.maxSpaceSpeed, tonumber(inputParts[2]))
                autoPilot:applyConfig()
                system.print([[Max Space Speed set to ]]..autoPilot.maxSpaceSpeed)
            end
        end

        if action == '/setmaxpitch' or action == '/setmp' then
            if tonumber(inputParts[2]) == nil then
            else
                autoPilot.userConfig.maxPitch = tonumber(inputParts[2])
                system.print([[Max Pitch set to ]]..autoPilot.userConfig.maxPitch)
                Config:setValue(configDatabankMap.maxPitch, autoPilot.userConfig.maxPitch)
            end
        end

        if action == '/setmaxroll' or action == '/setmr' then
            if tonumber(inputParts[2]) == nil then
            else
                autoPilot.userConfig.maxRoll = tonumber(inputParts[2])
                system.print([[Max Roll set to ]]..autoPilot.userConfig.maxRoll)
                Config:setValue(configDatabankMap.maxRoll, autoPilot.userConfig.maxRoll)
            end
        end

        if action == '/shield' then
            autoPilot.userConfig.shieldManage = not autoPilot.userConfig.shieldManage
            if autoPilot.userConfig.shieldManage then
                print('Shield management enabled')
            else
                print('Shield management disabled')
            end
            Config:setValue(configDatabankMap.shieldManage, autoPilot.userConfig.shieldManage)
        end

        if action == '/space' then
            autoPilot.userConfig.spaceCapableOverride = not autoPilot.userConfig.spaceCapableOverride   -- might just auto detect if space engines?
            if not autoPilot.userConfig.spaceCapableOverride then
                print('Space function disabled')
            else
                print('Space function enabled')
            end
            Config:setValue(configDatabankMap.spaceCapableOverride, autoPilot.userConfig.spaceCapableOverride)
        end
        
        if action == '/sethover' then
            if tonumber(inputParts[2]) == nil then
            else
                autoPilot:setHoverHeight(tonumber(inputParts[2]))
                system.print([[Hover height set to ]]..autoPilot.userConfig.hoverHeight)
            end
        end

        if action == '/atp' then
            autoPilot:toggleThrottleBurnProtection()
            if autoPilot.userConfig.throttleBurnProtection then
                print('Auto throttle burn protection enabled')
            else
                print('Auto throttle burn protection disabled')
            end
        end

        if action == '/alt' or action == '/altitude' then
            if tonumber(inputParts[2]) == nil then
            else  
            gCache.holdAltitude = tonumber(inputParts[2])
            system.print([[Altitude hold set to ]]..gCache.holdAltitude)
            end
        end

        if action == '/orbitalt' then
            if gCache.oribtalHold then
                if tonumber(inputParts[2]) == nil then
                    print('Error: did not enter a number')
                else  
                gCache.manualOrbitAlt = tonumber(inputParts[2])
                system.print([[Orbit Alt set to ]]..gCache.manualOrbitAlt)
                setTargetOrbitAlt()
                end
            else
            print('Error: Engage orbital hold mode first.')
            end
        end

        if action == '/radar' then -- toggle Radar Panel
            Radar:toggleWidget()
        end

        if action == '/radarbox' then
            Radar:toggleBoxes()
        end

        if action == '/unit' then
            _hud.toggleUnitWidget()
        end

        if action == '/freeze' then
            if getPlayerData().playerFrozen == true then
                player.freeze(false)
            else
                player.freeze(true)
            end
            print([[Frozen = ]] ..tostring(getPlayerData().playerFrozen))
        end

        if action == '/aggalt' then
            if links.antigrav ~= nil then
                if tonumber(inputParts[2]) == nil then
                    print('Error: did not enter a number')
                else  
                    links.antigrav.setTargetAltitude( tonumber(inputParts[2]) )
                    system.print([[AGG Alt set to ]]..tonumber(inputParts[2]))
                end
            end
        end

        if action == '/agg' then
            if links.antigrav ~= nil then
                links.antigrav.toggle()
            end
        end

        if action == '/inatmo' then
            print(gCache.inAtmo)
            print(links.shield.isActive())
        end

    end

end