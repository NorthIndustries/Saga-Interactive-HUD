function onSystemFlush()
    if (links.core ~= nil and construct ~= nil and axis ~= nil) then
        constructData = getConstructData(construct, links.core)
        applyShipInputs()
    end
end