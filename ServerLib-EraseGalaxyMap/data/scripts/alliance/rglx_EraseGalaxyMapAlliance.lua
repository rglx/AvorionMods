-- rglx's galaxy map eraser

--namespace EraseGalaxyMapAlliance
EraseGalaxyMapAlliance = {}
local self = EraseGalaxyMapAlliance


local finishedWipeKey = "rglx_GalaxyMapEraser_EraseToken" -- key to store the value under
local finishedWipeValue = "16feb2025" -- value to check against

if onServer() then

	function EraseGalaxyMapAlliance.initialize()
		-- main script components. checks for the presence of the value defined above, and then erases the galaxy map of the player if not present or exactly matching
		local alliance = Alliance()
		if alliance:getValue(finishedWipeKey) ~= finishedWipeValue then
			print("rglx_AllianceGalaxyMapEraser: Beginning erasure of " .. alliance.name .. "'s (#" .. alliance.index .. ") galaxy map...")

			local allianceKnownSectorsList = {alliance:getKnownSectors()}

			for i,sector in pairs(allianceKnownSectorsList) do
				local sectorX, sectorY = sector:getCoordinates()
				local sectorNote = sector.note
				local sectorIcon = sector.tagIconPath
				local sectorEntries = {sector:getCustomEntries()}
				local sectorEntriesCount = #sectorEntries
				--print(sectorX .. ":" .. sectorY , "name: ".. sector.name, "note: " .. sectorNote, "icon: ".. sectorIcon, "eCount: ".. #sectorEntries)
				if sectorIcon == "" and sectorNote == "" then
					--print("forgot about " .. sectorX .. ":" .. sectorY)
					alliance:removeKnownSector(sectorX,sectorY)
				else
					--print("remove & re-tag " .. sectorX .. ":" .. sectorY)
					local newSectorView = SectorView()
					newSectorView:setCoordinates(sectorX,sectorY)
					newSectorView.note = sectorNote
					newSectorView.tagIconPath = sectorIcon
					alliance:removeKnownSector(sectorX,sectorY)
					alliance:addKnownSector(newSectorView)
				end
			end

			print("rglx_AllianceGalaxyMapEraser: Completed erasure of Alliance " .. alliance.name .. "'s (#" .. alliance.index .. ") galaxy map, processing ".. #allianceKnownSectorsList .. " SectorViews.")
			alliance:setValue(finishedWipeKey, finishedWipeValue)


		else
			print("rglx_AllianceGalaxyMapEraser: Not erasing " .. alliance.name .. "'s (#" .. alliance.index .. ") galaxy map.")
		end


		terminate()
	end
else
	print("rglx_AllianceGalaxyMapEraser: script was loaded client-side, this will do nothing.")
end