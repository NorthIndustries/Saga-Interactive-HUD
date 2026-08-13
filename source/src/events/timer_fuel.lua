function onTimerFuelUpdate()
    --if not onStartCoroutineFinished then return end
    local curTime = system.getArkTime()
    for key, list in pairs(fuels) do
        for i, tank in ipairs(list) do
            tank.lastMass = tank.mass;
            tank.mass = links.core.getElementMassById(tank.uid) - globals.tankSizes[key][tank.size][1];
            if(tank.mass ~= tank.lastMass) then
                tank.percent = (tank.mass / tank.maxMass)*100;
                tank.lastTimeLeft = tank.timeLeft;
                tank.timeLeft = math.floor(tank.mass / ((tank.lastMass - tank.mass) / (curTime - tank.lastTime)))
                tank.lastTime = curTime;
            end 
        end
    end
end