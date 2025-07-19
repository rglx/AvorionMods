-- rglx's galaxy map eraser

-- checks a player for a value


--namespace EraseGalaxyMap
EraseGalaxyMap = {}
local self = EraseGalaxyMap


local finishedWipeKey = "rglx_GalaxyMapEraser_EraseToken" -- key to store the value under
local finishedWipeValue = "16feb2025" -- value to check against

if onServer() then

	function EraseGalaxyMap.initialize()
		-- main script components. checks for the presence of the value defined above, and then erases the galaxy map of the player if not present or exactly matching
		local player = Player()
		if player:getValue(finishedWipeKey) ~= finishedWipeValue then
			print("rglx_GalaxyMapEraser: Beginning erasure of " .. player.name .. "'s (#" .. player.index .. ") galaxy map...")

			local playerKnownSectorsList = {player:getKnownSectors()}

			for i,sector in pairs(playerKnownSectorsList) do
				local sectorX, sectorY = sector:getCoordinates()
				local sectorNote = sector.note
				local sectorIcon = sector.tagIconPath
				local sectorEntries = {sector:getCustomEntries()}
				local sectorEntriesCount = #sectorEntries
				--print(sectorX .. ":" .. sectorY , "name: ".. sector.name, "note: " .. sectorNote, "icon: ".. sectorIcon, "eCount: ".. #sectorEntries)
				if sectorIcon == "" and sectorNote == "" then
					--print("forget about " .. sectorX .. ":" .. sectorY)
					player:removeKnownSector(sectorX,sectorY)
				else
					--print("remove & re-tag " .. sectorX .. ":" .. sectorY)
					local newSectorView = SectorView()
					newSectorView:setCoordinates(sectorX,sectorY)
					newSectorView.note = sectorNote
					newSectorView.tagIconPath = sectorIcon
					player:removeKnownSector(sectorX,sectorY)
					player:addKnownSector(newSectorView)
				end
			end



			print("rglx_GalaxyMapEraser: Completed erasure of Player " .. player.name .. "'s (#" .. player.index .. ") galaxy map, processing ".. #playerKnownSectorsList .. " SectorViews.")
			player:setValue(finishedWipeKey, finishedWipeValue)


		else
			print("rglx_GalaxyMapEraser: Not erasing " .. player.name .. "'s (#" .. player.index .. ") galaxy map.")
		end

		terminate()
	end
else
	print("rglx_GalaxyMapEraser: script was loaded client-side, this will do nothing.")
end