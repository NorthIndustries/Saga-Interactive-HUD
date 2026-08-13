function addCustomPos(input)
    local pos = parsePosString(input)
    if pos.altitude == nil then
        print('Invalid ::pos{...} string')
    else
        addPos(pos)
    end
end

function addCurrentPos()
    local pos = {
        latitude = utils.round(constructData.constructPosition.x, 0.01),
        longitude = utils.round(constructData.constructPosition.y, 0.01),
        altitude = utils.round(constructData.constructPosition.z, 0.01),
    }
    addPos(pos)
end

function addPos(pos)
    local worldCoordinates = mapPosToWorldPos(pos)
    local systemId = pos.systemId
    local bodyId = pos.bodyId
    local coordinates = { x = pos.latitude, y = pos.longitude, z = pos.altitude }
    local coordinateBody = findClosestBody(worldCoordinates)
    local coordinateAltitude = getAltitude(worldCoordinates)
    local coordinateLoc = getLoc(coordinateBody, coordinateAltitude)
    --local coordinateString = table.concat({math.floor(pos.latitude), math.floor(pos.longitude), math.floor(pos.altitude)}, ',')
    --local name = coordinateBody.name .. ' ' .. coordinateLoc .. ' [' .. coordinateString .. ']'
    local name = coordinateBody.name .. ' ' .. coordinateLoc .. ' [' .. math.ceil(coordinateAltitude) .. 'm]'

    -- Only store body and system if non-zero
    if systemId == 0 then systemId = nil end
    if bodyId == 0 then bodyId = nil end
    local point = {
        name = name,
        coordinates = coordinates,
        systemId = systemId,
        bodyId = bodyId
    }
    RouteDatabase:addPoint(RouteDatabase.currentEditId, point)
    Widgets.mainMenu:onEditedRouteChanged()
end

function printPoint(option, arg)
    local pointIndex = arg
    local routeIndex = RouteDatabase.currentEditId
    local posString = RouteDatabase:getPointPosString(routeIndex, pointIndex)
    print(posString)
end

function setRouteDestination(option, arg)
    local routeIndex = arg
    AutoPilot:setActiveRoute(routeIndex)
end

function setPointDestination(option, arg)
    local pointIndex = arg
    local routeIndex = RouteDatabase.currentEditId
    AutoPilot:setActiveRoute(routeIndex, pointIndex)
end

function newRoute(option, arg)
    RouteDatabase:newRoute()
    Widgets.mainMenu:onEditedRouteChanged()
    Widgets.mainMenu.optionMenu:setPreviousCategoryKey(categoryENUM.EditRoute, categoryENUM.RouteList)
    Widgets.mainMenu.optionMenu:openCategory(categoryENUM.EditRoute)
end

function editRouteName(input, arg)
    --print('Rename route to ' .. input)
    RouteDatabase:renameRoute(RouteDatabase.currentEditId, input)
end

function editPointName(input, arg)
    --print('Rename [' .. RouteDatabase.currentEditId .. '] point [' .. arg .. '] to ' .. input)
    RouteDatabase:renamePoint(RouteDatabase.currentEditId, arg, input)
    Widgets.mainMenu:onEditedRouteChanged()
end

function getEditRouteName(option, arg)
    if RouteDatabase.currentEditId ~= nil and RouteDatabase.routes[RouteDatabase.currentEditId] ~= nil then
        return RouteDatabase.routes[RouteDatabase.currentEditId].name
    end
    return 'Invalid route id'
end

function editRoute(option, arg)
    --print('Editing route [' .. arg .. ']')
    RouteDatabase.currentEditId = arg
    Widgets.mainMenu:onEditedRouteChanged()
    Widgets.mainMenu.optionMenu:setPreviousCategoryKey(categoryENUM.EditRoute, categoryENUM.RouteListAll)
    Widgets.mainMenu.optionMenu:openCategory(categoryENUM.EditRoute)
end

function unEditRoute(option, arg)
    Widgets.mainMenu.optionMenu:setActiveOption(RouteDatabase.currentEditId - 1)
    RouteDatabase.currentEditId = nil
end

function deleteRoute(option, arg)
    RouteDatabase:deleteRoute(arg)
end

function deletePoint(option, arg)
    RouteDatabase:deletePoint(RouteDatabase.currentEditId, arg)
    Widgets.mainMenu:onEditedRouteChanged()
end

function movePoint(up, arg)
    local newPointIndex = RouteDatabase:movePoint(RouteDatabase.currentEditId, arg, ternary(up, arg - 1, arg + 1))
    Widgets.mainMenu.optionMenu:setActiveOption(newPointIndex + 2)
    Widgets.mainMenu:onEditedRouteChanged()
end

function selectDatabank(option, arg)
    if arg.type == 'config' then
        Config:selectDb(arg.databank)
    elseif arg.type == 'route' then
        RouteDatabase:selectDb(arg.databank)
    elseif arg.type == 'usb' then
        RouteDatabase:selectUsbDb(arg.databank)
    end
end

function setConfig(option, arg)
    Config:setValue(arg.key, arg.value)
end

function setConfigInput(input, arg)
    Config:setValue(arg, input)
end

function getActiveDbName(option, arg)
    if arg == 'config' and Config.databank ~= nil then
        return Config.databank.name
    elseif arg == 'routes' and RouteDatabase.databank ~= nil then
        return RouteDatabase.databank.name
    end
    return '-'
end

function menuActionTemplate(option, arg)
    
end
