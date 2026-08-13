function onSystemFlush()
    if (links.core ~= nil and construct ~= nil) then
        constructData = getConstructData(construct, links.core)
        applyShipInputs()
    end
end