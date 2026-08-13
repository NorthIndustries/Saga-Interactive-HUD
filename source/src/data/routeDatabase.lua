RouteDatabase = (
function()
    local this = {}

    this.dbDataKey = nil
    this.databank = nil
    this.databanks = nil
    this.usbDatabank = nil
    this.routes = {}
    this.currentEditId = nil
    
    function this:init(databanks, dbDataKey)
        this.dbDataKey = dbDataKey
        this.databanks = databanks
        
        EventSystem:register('ConfigDBChanged', this.applyConfig, this)
        this:applyConfig()
    end

    function this:applyConfig()
        -- Update databank names
        for i, databank in pairs(this.databanks) do
            databank.name = links.core.getElementNameById(databank.id)
        end

        -- Figure out the route databank
        this.databank = nil
        local selectedDbPriority = 0
        local routeDbName = Config:getValue(configDatabankMap.routeDatabankName)

        if routeDbName ~= nil then -- Config had a route databank selected
            for i, databank in pairs(this.databanks) do
                if databank.name == routeDbName then
                    this.databank = databank
                    selectedDbPriority = 3
                    break
                end
            end
        end

        if this.databank == nil then
            for i, databank in pairs(this.databanks) do
                -- Select first by default
                if this.databank == nil then this.databank = databank end
                
                -- Overwrite selection if the db contains relevant data
                local keysOnDb = databank.getKeyList()
                if table.contains(this.dbDataKey, keysOnDb) and selectedDbPriority <= 1 then
                    this.databank = databank
                    selectedDbPriority = 1
                end
            end
        end

        -- Figure out the usb databank
        local usbDbName = Config:getValue(configDatabankMap.usbDatabankName)

        if usbDbName ~= nil then -- Config had a usb databank selected
            for i, databank in pairs(this.databanks) do
                if databank.name == usbDbName then
                    this.usbDatabank = databank
                    break
                end
            end
        end

        this:load()
    end

    function this:selectDb(databank)
        this.databank = databank
        local dbName = links.core.getElementNameById(this.databank.id)
        Config:setValue(configDatabankMap.routeDatabankName, dbName)
        this:load()
    end

    function this:selectUsbDb(databank)
        this.usbDatabank = databank
        local dbName = links.core.getElementNameById(this.usbDatabank.id)
        Config:setValue(configDatabankMap.usbDatabankName, dbName)
    end

    function this:save()
        EventSystem:trigger('RoutesUpdated')
        if this.databank == nil then return end
        this.databank.setStringValue(this.dbDataKey, serialize(this.routes))
    end

    function this:load()
        if this.databank == nil then return end
        this.routes = {}
        local dbStringValue = this.databank.getStringValue(this.dbDataKey)
        if dbStringValue ~= '' then
            local dbLoad, err = load('return ' .. dbStringValue)
            if dbLoad == nil then
                print('Error loading routes from databank')
                print(dbStringValue)
                print(err)
            else
                local routesOnDatabank = dbLoad()
                if routesOnDatabank ~= nil then
                    this.routes = routesOnDatabank
                    table.sort(this.routes, function(a,b) return a.name < b.name end)
                end
            end
        end
        EventSystem:trigger('RoutesUpdated')
    end

    function this:beforeRoutesChanged()
        if this.currentEditId ~= nil then
            this.shouldFindEdit = true
            this.routes[this.currentEditId].edit = true
        end
        if AutoPilot.currentRouteIndex ~= nil then
            this.shouldFindActive = true
            this.routes[AutoPilot.currentRouteIndex].active = true
        end
    end

    function this:routesChanged()
        local foundEdit = false
        local foundActive = false

        table.sort(this.routes, function(a,b) return a.name < b.name end)

        for i,route in ipairs(this.routes) do
            -- Automatically "open" fresh routes
            if route.fresh == true then
                route.fresh = nil
                this.currentEditId = i
            end
            -- Fix the current edit
            if route.edit == true then
                route.edit = nil
                this.currentEditId = i
                foundEdit = true
            end
            -- Fix the AP route index
            if route.active == true then
                route.active = nil
                AutoPilot.currentRouteIndex = i
                foundActive = true
                Config:setDynamicValue(configDatabankMap.currentTarget, {AutoPilot.currentRouteIndex,AutoPilot.currentPointIndex,this.databank.name})
            end
        end

        -- The edit route wasn't found
        if this.shouldFindEdit and not foundEdit then
            this.currentEditId = nil
        end
        -- The active route wasn't found
        if this.shouldFindActive and not foundActive then
            AutoPilot:onRouteUnloaded()
        end

        this.shouldFindEdit = false
        this.shouldFindActive = false

        this:save()
    end

    function this:newRoute()
        local route = {
            name = 'Route ' .. (#this.routes + 1),
            points = {},
            fresh = true
        }
        this:beforeRoutesChanged()
        table.insert(this.routes, route)
        this:routesChanged()
        return route
    end

    function this:addPoint(index, point)
        table.insert(this.routes[index].points, point)
        this:save()
    end

    function this:deleteRoute(index)
        this:beforeRoutesChanged()
        table.remove(this.routes, index)
        this:routesChanged()
    end

    function this:deletePoint(routeIndex, pointIndex)
        if this.routes[routeIndex] == nil then return end
        if this.routes[routeIndex].points == nil then return end
        if this.routes[routeIndex].points[pointIndex] == nil then return end
        if AutoPilot.currentRouteIndex == routeIndex and AutoPilot.currentPointIndex >= pointIndex then
            AutoPilot.currentPointIndex = AutoPilot.currentPointIndex - 1
        end
        table.remove(this.routes[routeIndex].points, pointIndex)
        this:save()
    end

    function this:renameRoute(index, name)
        if this.routes[index] == nil then return end
        this:beforeRoutesChanged()
        this.routes[index].name = name
        this:routesChanged()
    end

    function this:renamePoint(routeIndex, pointIndex, name)
        if this.routes[routeIndex] == nil then return end
        if this.routes[routeIndex].points == nil then return end
        if this.routes[routeIndex].points[pointIndex] == nil then return end
        this.routes[routeIndex].points[pointIndex].name = name
        this:save()
    end

    function this:movePoint(routeIndex, oldPointIndex, newPointIndex)
        if this.routes[routeIndex] == nil then return end
        if this.routes[routeIndex].points == nil then return end
        local pointCount = #this.routes[routeIndex].points
        local point = table.remove(this.routes[routeIndex].points, oldPointIndex)
        if newPointIndex > pointCount then newPointIndex = pointCount end
        if newPointIndex < 1 then newPointIndex = 1 end
        table.insert(this.routes[routeIndex].points, newPointIndex, point)
        if AutoPilot.currentRouteIndex == routeIndex then
            if AutoPilot.currentPointIndex == oldPointIndex then
                AutoPilot.currentPointIndex = newPointIndex
            elseif AutoPilot.currentPointIndex == newPointIndex then
                AutoPilot.currentPointIndex = oldPointIndex
            end
        end
        this:save()
        return newPointIndex
    end

    function this:getRoutePointCount(routeIndex)
        if this.routes[routeIndex] == nil then return 0 end
        if this.routes[routeIndex].points == nil then return 0 end
        return #this.routes[routeIndex].points
    end

    function this:getPointCoordinates(routeIndex, pointIndex)
        if this.routes[routeIndex] == nil then return end
        if this.routes[routeIndex].points == nil then return end
        if this.routes[routeIndex].points[pointIndex] == nil then return end

        local point = this.routes[routeIndex].points[pointIndex]
        local systemId = 0
        local bodyId = 0
        if point.systemId ~= nil and point.systemId ~= 0 then -- It has a body id
            systemId = point.systemId
        end
        if point.bodyId ~= nil and point.bodyId ~= 0 then -- It has a body id
            bodyId = point.bodyId
        end
        local worldPos = mapPosToWorldPos({
            latitude  = point.coordinates.x,
            longitude = point.coordinates.y,
            altitude  = point.coordinates.z,
            bodyId    = bodyId,
            systemId  = systemId
        })
        return worldPos
    end

    function this:getPointPosString(routeIndex, pointIndex)
        if this.routes[routeIndex] == nil then return end
        if this.routes[routeIndex].points == nil then return end
        if this.routes[routeIndex].points[pointIndex] == nil then return end

        local point = this.routes[routeIndex].points[pointIndex]
        local systemId = 0
        local bodyId = 0
        if point.systemId ~= nil then systemId = point.systemId end
        if point.bodyId ~= nil then bodyId = point.bodyId end

        local pointConcat = table.concat({systemId,bodyId,point.coordinates.x,point.coordinates.y,point.coordinates.z}, ',')
        local pointPosString = '::pos{' .. pointConcat .. '}'
        return pointPosString
    end

    function this:getDatabankName()
        if this.databank == nil then return end
        return this.databank.name
    end

    return this
end
)()