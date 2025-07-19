-- rglx's server-side docked stations finder
-- logs when stations in its sector have things docked to them.

--namespace LogDockedStations
LogDockedStations = {}
local self = LogDockedStations -- won't work for functions

if onServer() then
	-- only do things on the server-side
	
	function LogDockedStations.initialize()
		local sector = Sector()
		local dockingParents = {}
		local sectorX, sectorY = sector:getCoordinates()

		-- exit if we have no stations in this sector
		if sector:getNumEntitiesByType(EntityType.Station) == 0 then terminate() end

		local allStationsInSector = {sector:getEntitiesByType(EntityType.Station)}

		for _,station in pairs(allStationsInSector) do
			-- iterate through each station in the sector
			if station.aiOwned == false then
				-- refuse to work on stations owned by NPCs
				if station.dockingParent then
					--print( station.name .. " is docked to " .. station.dockingParent.string )
					-- station has a docking parent! let's increment our counters
					if dockingParents[station.dockingParent.string] == nil then
						-- add that ID to docking parents list
						dockingParents[station.dockingParent.string] = 1
					else
						-- increment existing counter
						dockingParents[station.dockingParent.string] = dockingParents[station.dockingParent.string] + 1
					end
				end
			end
		end

		for parentId,childCount in pairs(dockingParents) do
			local parentEntity = Entity(parentId)
			print("rglx_LogDockedStations: sector (" .. sectorX .. ":" .. sectorY .. ") has a station complex called " .. parentEntity.name .. " with " .. childCount .. " stations docked to it, owned by " .. Faction(parentEntity.factionIndex).fullLogId)
		end

		-- and finally, exit gracefully
		terminate()

	end

else
	eprint("rglx_LogDockedStations: cowardly refusing to work client-side on a sector.")
end