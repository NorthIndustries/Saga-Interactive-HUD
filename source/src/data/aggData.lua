function getAggData()
    if links.antigrav ~= nil then
        local agg = links.antigrav
        local inBubble = false
        local curAltitude = constructData.altitude
        local aggAlt = agg.getBaseAltitude()
        if curAltitude > aggAlt - 100 and curAltitude < aggAlt + 100 and agg.isActive() == 1 then
            inBubble = true
        end
        return {
            aggState = agg.isActive(),
            aggStrength = agg.getFieldStrength(),
            aggRate = agg.getCompensationRate(),
            aggPower = agg.getFieldPower(),
            aggPulsor = agg.getPulsorCount(),
            aggTarget = agg.getTargetAltitude(),
            aggAltitude = aggAlt,
            aggBubble = inBubble
        }
    else --Temporarily forcing values as im not testing with an AGG ship
        return {
            aggState = 0,
            aggStrength = 0,
            aggRate = 0,
            aggPower = 5,
            aggPulsor = 5,
            aggAltitude = 9001,
            aggTarget = 9001,
            aggAltitude = 9001,
            aggBubble = false
        }
    end
end