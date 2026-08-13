function scanLinks()
	links = {
	    core = nil,
	    warpdrive = nil,
	    shield = nil,
	    antigrav = nil,
	    gyro = nil,
		transponder = nil,
        databanks = {},
	    weapons = {},
		switches = {},
		electronics = nil,
		radars = {},
		engine = nil -- temp for testing some engine info
    }
	
	for slotName, slot in pairs(unit) do
		if
			type(slot) == "table"
			and type(slot.export) == "table"
			and slot.getClass
		then
			local elementClass = slot.getClass():lower()
            slot.slotName = slotName
            slot.elementClass = elementClass
			if elementClass:find("coreunit") then
				links.core = slot
			elseif elementClass:find("radar") then
				table.insert(links.radars, slot)
			elseif elementClass:find("warpdriveunit") then
				links.warpdrive = slot
			elseif elementClass:find("databankunit") then
				table.insert(links.databanks, slot)
			elseif elementClass:find("shieldgenerator") then
				links.shield = slot
			elseif elementClass:find("weapon") then
				table.insert(links.weapons, slot)
			elseif elementClass:find("gyrounit") then
				links.gyro = slot
			elseif elementClass:find("antigravitygeneratorunit") then
				links.antigrav = slot
			elseif elementClass:find("combatdefense") then
				links.transponder = slot
			elseif elementClass:find('manualswitchunit') then
				table.insert(links.switches, slot)
			--elseif elementClass:find("atmosphericengine") then
			--	links.engine = slot
			else
				--print(elementClass)
			end
		end
	end
end

-- Remaps have been done
function finaliseLinks()
    links.electronics = Electronics

    -- Databank names
    for i,databank in ipairs(links.databanks) do
        databank.id = databank.getLocalId()
        databank.name = links.core.getElementNameById(databank.id)
    end
    -- Databank sorting
    table.sort(links.databanks, function(a,b) return a.id < b.id end)

    -- Switch categorization
    for _,switch in ipairs(links.switches) do
        local switchName = links.core.getElementNameById(switch.getLocalId())
        if switchName:lower():find('door') then
            table.insert(links.electronics.doors, switch)
        elseif switchName:lower():find('forcefield') then
            table.insert(links.electronics.forcefields, switch)
        else
            table.insert(links.electronics.switches, switch)
        end
    end

    -- Radar typing
    for i,radar in ipairs(links.radars) do
        radar.pvp = (radar.slotName == 'slot21' or radar.slotName == 'slot14')
    end
end