-- rglx's attempt at forcing the station rebuilder to run a lot more frequently- should help galaxies keep ships alive and not dead.

-- namespace RebuildStations

-- we have to unsafely clobber the vanilla function because there's a random chance that a faction will simply not attempt to reconstruct a station
--local stashedRebuildServerUpdateServer = RebuildStations.updateServer
function RebuildStations.updateServer(timeStep)
    local sector = Sector()

    -- retrieve generation specifications if something hasn't already grabbed them
    if not RebuildStations.specsInitialized then
        RebuildStations.initializeSpecs(sector:getCoordinates())
        RebuildStations.specsInitialized = true
    end

    -- step our timer forward, and check if enough time has passed to let us build
    RebuildStations.updateTimer = RebuildStations.updateTimer + timeStep
    if RebuildStations.updateTimer < 10 * 60 then
        return
    end

    -- reset our timer
    RebuildStations.updateTimer = 0

    -- remove 80% random chance to bail
    --if not random():test(0.2) and not RebuildStations.isUnitTestActive then
    if not RebuildStations.isUnitTestActive then
        return
    end

    -- if the generation specs say no faction lives here, bail
    if not RebuildStations.specsFactionIndex then
        return
    end

    -- now begins our code...
    localFaction = Faction(RebuildStations.specsFactionIndex)

    -- we need to force our sectors to always regenerate lost stations every ten minutes if we can
    -- unfortunately this will only let one station generate roughly every half hour *FACTIONWIDE*
    -- this breaks down pretty hard especially if you don't have people in those sectors, so speeding this
    -- up will help rebuild destroyed stations much more aggressively.

    lastTimestamp = localFaction:getValue("rebuild_stations_timestamp")
    if lastTimestamp and lastTimestamp > 1 then
        -- only want to do this if that timestamp is greater than 1
        -- i.e. the rebuilder function ran, and put Server().unpausedRumtime into this entity value
        -- we won't do anything unless that timestamp has been set.
        print("rglx_ServerLib_ForceFactionsToRebuild: overrode a timestamp from rebuildstations.lua! Faction '".. localFaction.name .. "' (#".. localFaction.index ..") has rebuilt a station somewhere.")
        localFaction:setValue("rebuild_stations_timestamp",0)
    end

    -- alright, we're done. let's continue as normal

    -- gather data
    local currentContents = RebuildStations.getCurrentContents()

    -- update
    RebuildStations.updateConstruction(currentContents)

end