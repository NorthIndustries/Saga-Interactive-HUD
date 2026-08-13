function onUnitStart(_system, _unit, _construct, _library, _player)
    system = _system
    unit = _unit
    construct = _construct
	library = _library
	player = _player

    remapBeforeInit()

	system.showHelper(false)

	scanLinks()
	if links.core == nil then
		print("Core not found, did you link it to this control unit?")
	else
		init()
		
		remapAfterInit() -- links, construct and Nav remappings
		finaliseLinks()
	
		constructData = getConstructData(construct, links.core)
		playerData = getPlayerData()
		aggData = getAggData()
		warpData = getWarpData()
	
		Config:init(links.databanks, 'SagaConf', 'SagaActiveConf')
		RouteDatabase:init(links.databanks, 'SagaRoutes', 'SagaActiveRoutes')
		Radar:init(links.radars)
		AutoPilot:init()
		SoundSystem:init()

		initializeTanks()
		initEngines()
		--initRadar()
		resetAP()
	
		printHello()
		
		HUD:init()
		links.electronics:SwitchesOn()
	
		Nav.axisCommandManager.axisCommands[axisCommandId.longitudinal].throttleMouseStepScale = 1
		Nav.targetSpeedRanges = {1000, 5000, 10000, 20000, 30000}
		Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, Nav.targetSpeedRanges)
		Nav.axisCommandManager:setTargetGroundAltitude(0)
		unit.setTimer('DEBUGHUD',0.1)
	end

end

function init()
    constructData = {}
	aggData = {}
	warpData = {}
	playerData = {}

	Nav = Navigator.new(system, links.core, unit)

	--SZ Center (13771471,7435803,-128971) --dropping here for use later.

	vector = vec3()
	targetAngularVelocity = vec3()
	atlas = require('atlas')
	initialiseAtlas()
	systemId = 0

	dynamicSVG()
end

function printHello()
    system.print('HUD/Autopilot by Sagacious, Mayumi and CodeInfused')
    system.print('v' .. getVersionString())
	system.print('Discord: https://discord.gg/jTu8W8tXph')
	SoundSystem:playSound(SoundFiles.startup)
end

function initEngines()
	local gCache = globals
	local primaryTags = 'primary'
	local secondaryTags = 'secondary'
	local tertiaryTags = 'tertiary'
	local defaultTags = 'thrust analog longitudinal'
	local boostModeOverride = 'off' --export: (Engine Throttle Mode Override) -- 'off' , 'all' , 'hybrid' , 'primary' -- if using Engine tags(see instructions), default engine control mode when activating control unit. 
	
	
	gCache.maxPrimaryKP = construct.getMaxThrustAlongAxis(primaryTags, {vec3(construct.getForward()):unpack()})
	gCache.maxSecondaryKP = construct.getMaxThrustAlongAxis(secondaryTags, {vec3(construct.getForward()):unpack()})
	gCache.maxTertiaryKP = construct.getMaxThrustAlongAxis(secondaryTags, {vec3(construct.getForward()):unpack()})
	gCache.maxDefaultKP = construct.getMaxThrustAlongAxis(defaultTags, {vec3(construct.getForward()):unpack()})
	
	if AutoPilot.userConfig.spaceCapableOverride == false then
		if gCache.maxDefaultKP[3] > 0 then
			gCache.spaceCapable = true
		else
			gCache.spaceCapable = false
			print('longitudinal Space Thrust not detected - space transfers/orbit disabled')
		end
	else
		gCache.spaceCapable = AutoPilot.userConfig.spaceCapableOverride
	end
	
	if boostModeOverride == 'off' then
		if (gCache.maxPrimaryKP[1] > 0 and gCache.maxSecondaryKP[1] > 0) then
			gCache.advAtmoEngines = true
			gCache.boostMode = 'hybrid'
			print('Atmo Engine tags detected, advanced Atmo engine control enabled')
		else
			gCache.advAtmoEngines = false
			print('Atmo Engine tags not detected, advanced Atmo engine control disabled')
		end

		if (gCache.maxPrimaryKP[3] > 0 and gCache.maxSecondaryKP[3] > 0) then
			gCache.advSpaceEngines = true
			gCache.boostMode = 'hybrid'
			print('Space Engine tags detected, advanced Space engine control enabled')
		else
			gCache.advSpaceEngines = false
			print('Space Engine tags not detected, advanced Space engine control disabled')
		end
	else
		gCache.boostMode = boostModeOverride
	end
	
	--[[
	print(maxPrimaryKP[1]) --Atmo Forward
	print(maxPrimaryKP[2]) --Atmo Backward
	print(maxPrimaryKP[3]) --SpaceForward
	print(maxPrimaryKP[4]) --SpaceBackward
	print(maxSecondaryKP[1]) --Atmo Forward
	print(maxSecondaryKP[2]) --Atmo Backward
	print(maxSecondaryKP[3]) --SpaceForward
	print(maxSecondaryKP[4]) --SpaceBackward
	]]
end

--WIP-----------------
function getEnemyPos(system,radar)
    local id = radar.getTargetId()
    local dist = radar.getConstructDistance(id)
    local forwardVector = vec3(system.getCameraWorldForward())
    local worldpos = vec3(system.getCameraWorldPos())
    local pos = (dist * forwvector + worldpos)
    local x,y,z = pos:unpack()
    local waypoint = '::pos{0,0,'..x..','..y..','..z..'}'
    system.setWaypoint(waypoint)
	return waypoint
end
----------------