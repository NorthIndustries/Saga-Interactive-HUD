function onSystemUpdate()
    if (links.core ~= nil and construct ~= nil) then
        constructData = getConstructData(construct, links.core)
        playerData = getPlayerData()
        aggData = getAggData()
        warpData = getWarpData()
        local gCache = globals

        Nav:update()
        HUD:update()
        Radar:update()
        Electronics:update()
        onTimerAPU()

        --[[
        Axis	Description	        Dir
        Axis0	Roll	            +
        Axis1	Pitch	            +
        Axis2	Yaw	                +
        Axis3	Throttle	        -
        Axis4	Brake	            -
        Axis5	Strafe Left/Right	?1
        Axis6	Vertical Up/Down	?1
        Axis7	Custom2	?1
        Axis8	Custom2	?1
        Axis9	Custom2	?1
        ]]

        if AutoPilot.enabled or gCache.followMode or gCache.orbitalHold then
            axis = {
                rollAxis = 0,
                pitchAxis = 0,
                yawAxis = 0,
                updownAxis = 0,
                leftrightAxis = 0,
                forwardbackAxis = 0,
                brakeAxis = 0,
                throttle1Axis = 0,
                throttle2Axis = 0,
                throttle3Axis = 0
            }
        else
            axis = {
                rollAxis = -system.getAxisValue(0),
                pitchAxis = -system.getAxisValue(1),
                yawAxis = system.getAxisValue(2),
                throttle1Axis = system.getAxisValue(3),
                brakeAxis = -system.getAxisValue(4),
                leftrightAxis = system.getAxisValue(5),
                updownAxis = system.getAxisValue(6),
                forwardbackAxis = system.getAxisValue(7),
                throttle2Axis = system.getAxisValue(8),
                throttle3Axis = system.getAxisValue(9)
            }
        end
        --onTimerFuelUpdate()
        --[[
        for i, entry in ipairs(Radar.radarTestList) do
            print(entry)
        end
        ]]
        --[[
        print('Max= '..maxPrimaryKP[1])
        print('current= ' ..links.engine.getThrust())
        print(utils.round((links.engine.getThrust()/maxPrimaryKP[1])*100,0.01))
        print('throttle ' ..unit.getThrottle())
        ]]
    end
end