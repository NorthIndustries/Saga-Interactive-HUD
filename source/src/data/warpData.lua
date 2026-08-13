function getWarpData()
    if links.warpdrive ~= nil then
        local warpStatus = links.warpdrive.getStatus()
        if warpStatus == 1 then
            warpStatus = 'No Warpdrive'
        elseif warpStatus == 2 then
            warpStatus = 'Broken'
        elseif warpStatus == 3 then
            warpStatus = 'Warping'
        elseif warpStatus == 4 then
            warpStatus = 'Parent Warping'
        elseif warpStatus == 5 then
            warpStatus = 'Not Seated'
        elseif warpStatus == 6 then
            warpStatus = 'Warp Cooldown'
        elseif warpStatus == 7 then
            warpStatus = 'PvP Cooldown'
        elseif warpStatus == 8 then
            warpStatus = 'Moving Docked Ship'
        elseif warpStatus == 9 then
            warpStatus = 'No Container Linked'
        elseif warpStatus == 10 then
            warpStatus = 'Planet Too Close'
        elseif warpStatus == 11 then
            warpStatus = 'Destination Not Set'
        elseif warpStatus == 12 then
            warpStatus = 'Destination Too Close'
        elseif warpStatus == 13 then
            warpStatus = 'Destination Too Far'
        elseif warpStatus == 14 then
            warpStatus = 'Not Enough Cells'
        elseif warpStatus == 15 then
            warpStatus = 'Ready'
        end
        local warpDistance = links.warpdrive.getDistance()
        local warpDestination = links.warpdrive.getDestinationName()
        if warpStatus == 'Destination Not Set' then
            warpDestination = 'No Destination'
        end
        local warpCells = links.warpdrive.getAvailableWarpCells()
        local warpCellsNeeded = links.warpdrive.getRequiredWarpCells()
        return {
            warpStatus = warpStatus,
            warpDistance = warpDistance,
            warpDestination = warpDestination,
            warpCells = warpCells,
            warpCellsNeeded = warpCellsNeeded
        }
    else
        return {
            warpStatus = 'Ready',
            warpDistance = 42000,
            warpDestination = 'No Destination',
            warpCells = 42,
            warpCellsNeeded = 42
        }
    end
end