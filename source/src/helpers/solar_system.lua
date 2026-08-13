function findClosestBodyId(coordinates)
	local closestBody = findClosestBody(coordinates)
	return closestBody.bodyId
end

function findClosestBody(coordinates)
	local minDistance = math.huge
	local closestBody = nil
	for _,planet in pairs(atlas[systemId]) do
		local distance = vector.dist(coordinates, planet.center)
		if distance < minDistance then
			minDistance = distance
			closestBody = planet
		end
	end
	return closestBody, minDistance
end

function parsePosString(posString)
	local num = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
	local systemId, bodyId, latitude, longitude, altitude = string.match(posString, '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}')
	
	systemId  = tonumber(systemId)
	bodyId    = tonumber(bodyId)
	latitude  = tonumber(latitude)
	longitude = tonumber(longitude)
	altitude  = tonumber(altitude)

    return {
		latitude  = latitude,
		longitude = longitude,
		altitude  = altitude,
		bodyId    = bodyId,
		systemId  = systemId
	}
end

-- Convert a ::pos string to world coordinates
function convertToWorldCoordinates(posString)
	local mapPosition = parsePosString(posString)
	return mapPosToWorldPos(mapPosition)
end

function mapPosToWorldPos(mapPosition)
	if mapPosition.altitude == nil then 
		return nil 
	end
	if mapPosition.bodyId == nil or mapPosition.bodyId == 0 then -- support deep space map position
		return vec3(mapPosition.latitude,
					mapPosition.longitude,
					mapPosition.altitude)
	end
	local lat = constants.deg2rad*utils.clamp(mapPosition.latitude, -90, 90)
	local lon = constants.deg2rad*(mapPosition.longitude % 360)
	local xproj = math.cos(lat)
	local planet = atlas[mapPosition.systemId][mapPosition.bodyId]
	return vec3(planet.center) + (planet.radius + mapPosition.altitude) *
		   vec3(xproj*math.cos(lon),
				xproj*math.sin(lon),
				math.sin(lat))
end

function initialiseAtlas()
	for system,systemData in pairs(atlas) do
		for bodyId,planet in pairs(systemData) do
			planet.bodyId = bodyId
			planet.center = vec3(planet['center'])
			planet.gravity = planet['gravity']
			planet.GM = planet['GM']
			planet.name = planet['name'][1]
			planet.type = planet['type'][1]
			planet.radius = planet['radius']
			planet.atmoRadius = planet['atmosphereRadius']
			planet.satellites = planet['satellites']
			planet.hasAtmosphere = planet['hasAtmosphere']
			planet.surfaceMaxAltitude = planet["surfaceMaxAltitude"]
			planet.surfaceMinAltitude = planet["surfaceMinAltitude"]
			local planetOreList = {}
			for i,ore in ipairs(planet['ores']) do
				table.insert(planetOreList, ore)
			end
			planet.ore = planetOreList
			
			if planet['hasAtmosphere'] then planet.atmoAltitude = planet['atmosphereRadius'] - planet.radius end
			
		end
	end
	for system,systemData in pairs(atlas) do
		for bodyId,planet in pairs(systemData) do
			if planet.satellites ~= nil then
				for i,satelliteId in pairs(planet.satellites) do
					atlas[system][satelliteId].parentBodyId = bodyId
				end
			end
		end
	end
end

function castIntersections()
	local origin = constructData.constructPosition
	local dir = constructData.worldVelocityDirection

	for _,planet in pairs(atlas[systemId]) do
		local size = 200000
		if planet.hasAtmosphere then
			size = planet.atmoRadius*1.2
		else
			size = planet.radius*1.4
		end
		local c_oV3 = planet.center - origin

		local dot = c_oV3:dot(dir)
		local desc = dot ^ 2 - (c_oV3:len2() - size ^ 2)
		if desc >= 0 then
			local root = math.sqrt(desc)
			local farSide = dot + root
			local nearSide = dot - root
			if nearSide > 0 then
				return planet, farSide, nearSide
			elseif farSide > 0 then
				return planet, farSide, nil
			end
		end
	end
	return nil, nil, nil
end

function checkLOS(vector)
	local worldPos = constructData.constructPosition
	local body = findClosestBody(worldPos)
	local size = 200000
	if body.hasAtmosphere == 1 then
		size = body.atmoRadius*1.05
	else
		size = body.radius*1.2
	end
	local intersectBody, farSide, nearSide = castIntersections(worldPos, vector, size) --no longer needed? refined castIntersectons function
	local atmoDistance = farSide
	if nearSide ~= nil and farSide ~= nil then
		atmoDistance = math.min(nearSide,farSide)
	end
	if atmoDistance ~= nil then return intersectBody, atmoDistance else 
		return nil, nil 
	end
end

function getAltitude(coordinates)
    local dist = 0
	if coordinates == nil then
		if links.core.getAltitude() == 0 then
			coordinates = constructData.constructPosition
			local body = findClosestBody(coordinates)
			dist = vector.dist(vec3(body.center), coordinates) - body.radius
		else
			dist = links.core.getAltitude()
		end
	else
		coordinates = vec3(coordinates)
		local body = findClosestBody(coordinates)
		dist = vector.dist(vec3(body.center), coordinates) - body.radius
	end
	return utils.round(dist)
end


function getOrbitalParameters(constructData)
    local body = findClosestBody(constructData.constructPosition)
    local pos = constructData.constructPosition
    local v = constructData.worldVelocity
    local r = pos - body.center
    local v2 = v:len2()
    local d = r:len()
    local mu = body.GM
    local e = ((v2 - mu / d) * r - r:dot(v) * v) / mu
    local a = mu / (2 * mu / d - v2)
    local ecc = e:len()
    local dir = e:normalize()
    local pd = a * (1 - ecc)
    local ad = a * (1 + ecc)
    local per = pd * dir + body.center
    local apo = ecc <= 1 and -ad * dir + body.center or nil
    local trm = math.sqrt(a * mu * (1 - ecc * ecc))
    local Period = apo and 2 * math.pi * math.sqrt(a ^ 3 / mu)
    -- These are great and all, but, I need more.
    local trueAnomaly = math.acos((e:dot(r)) / (ecc * d))
    if r:dot(v) < 0 then
        trueAnomaly = -(trueAnomaly - 2 * math.pi)
    end
    -- Apparently... cos(EccentricAnomaly) = (cos(trueAnomaly) + eccentricity)/(1 + eccentricity * cos(trueAnomaly))
    local EccentricAnomaly = math.acos((math.cos(trueAnomaly) + ecc) / (1 + ecc * math.cos(trueAnomaly)))
    -- Then.... apparently if this is below 0, we should add 2pi to it
    -- I think also if it's below 0, we're past the apoapsis?
    local timeTau = EccentricAnomaly
    if timeTau < 0 then
        timeTau = timeTau + 2 * math.pi
    end
    -- So... time since periapsis...
    -- Is apparently easy if you get mean anomly.  t = M/n where n is mean motion, = 2*pi/Period
    local MeanAnomaly = timeTau - ecc * math.sin(timeTau)
    local TimeSincePeriapsis = 0
    local TimeToPeriapsis = 0
    local TimeToApoapsis = 0
    if Period ~= nil then
        TimeSincePeriapsis = MeanAnomaly / (2 * math.pi / Period)
        -- Mean anom is 0 at periapsis, positive before it... and positive after it.
        -- I guess this is why I needed to use timeTau and not EccentricAnomaly here

        TimeToPeriapsis = Period - TimeSincePeriapsis
        TimeToApoapsis = TimeToPeriapsis + Period / 2
        if trueAnomaly - math.pi > 0 then -- TBH I think something's wrong in my formulas because I needed this.
            TimeToPeriapsis = TimeSincePeriapsis
            TimeToApoapsis = TimeToPeriapsis + Period / 2
        end
        if TimeToApoapsis > Period then
            TimeToApoapsis = TimeToApoapsis - Period
        end
    end
    return {
        periapsis = {
            position = per,
            speed = trm / pd,
            circularOrbitSpeed = utils.round(math.sqrt(mu / pd)),
            altitude = utils.round(pd - body.radius)
        },
        apoapsis = {
            position = apo,
            speed = trm / ad,
            circularOrbitSpeed = utils.round(math.sqrt(mu / ad)),
            altitude = utils.round(ad - body.radius)
        },
        currentVelocity = v,
        currentPosition = pos,
        eccentricity = ecc,
        period = Period,
        eccentricAnomaly = EccentricAnomaly,
        meanAnomaly = MeanAnomaly,
        timeToPeriapsis = utils.round(TimeToPeriapsis),
        timeToApoapsis = utils.round(TimeToApoapsis),
        trueAnomaly = trueAnomaly
    }
end

function getOrbitalSpeed(altitude, planet)
    -- P = -GMm/r and KE = mv^2/2 (no lorentz factor used)
    -- mv^2/2 = GMm/r
    -- v^2 = 2GM/r
    -- v = sqrt(2GM/r1)
    local distance = altitude + planet.radius

    if distance > 0 then
        local orbit = math.sqrt(planet.GM/distance)
        return orbit
    end
    return nil
end

function getOrbitFocus(constructData)
    local apo = constructData.orbitalParameters.apoapsis.altitude
    local peri = constructData.orbitalParameters.periapsis.altitude
    local timeApo = constructData.orbitalParameters.timeToApoapsis
    local timePer = constructData.orbitalParameters.timeToPeriapsis
    local orbitSpeed = 0
    if timeApo <= timePer then
        orbitAltTarget = apo
        orbitSpeed = constructData.orbitalParameters.apoapsis.circularOrbitSpeed
    else
        orbitAltTarget = peri
        orbitSpeed = constructData.orbitalParameters.periapsis.circularOrbitSpeed
    end
 
    return {orbitAltTarget = orbitAltTarget, orbitSpeed = orbitSpeed}
end