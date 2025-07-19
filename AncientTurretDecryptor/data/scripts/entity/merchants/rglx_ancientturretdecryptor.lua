-- rglx's turret decryptor for turret factories.
-- decrypt turrets in exchange for resources

package.path = package.path .. ";data/scripts/lib/?.lua"
include ("utility")
include ("player")
include ("faction")
include ("defaultscripts")
include ("randomext")
include ("stationextensions")
include ("galaxy")
include ("randomext")
include ("faction")
include ("player")
include ("stringutility")
include ("callable")
local SellableInventoryItem = include ("sellableinventoryitem")
local Dialog = include("dialogutility")

-- dont remove this next line. used by the game's engine.
-- namespace AncientTurretDecryptor
AncientTurretDecryptor = {}
local self = AncientTurretDecryptor

AncientTurretDecryptor.interactionThreshold = 30000
local inventory = nil
local decryptButton = nil
local decryptionCostMultiplier = 10
print("rglx_AncientTurretDecryptor: load attempt")

function AncientTurretDecryptor.initialize()
	print("rglx_AncientTurretDecryptor: initialize()")
	return
end

function AncientTurretDecryptor.interactionPossible(playerIndex, option)
	return CheckFactionInteraction(playerIndex, AncientTurretDecryptor.interactionThreshold)
end


function AncientTurretDecryptor.initializationFinished()
	print("rglx_AncientTurretDecryptor: initializationFinished(): started")
	-- add some more flavor text
	if onClient() then
		local ok, r = Sector():invokeFunction("radiochatter", "addSpecificLines", Entity().id.string,
		{
			"New service: Ancient Technology Decryption!",
			"We offer Ancient Tech Decryption services. The old stuff is the good stuff!",
			"Got a cool new turret but it's based on ancient technology? We can fix that. Talk to our decryption kiosk today.",
		})
	end
	print("rglx_AncientTurretDecryptor: initializationFinished(): done")
end


function AncientTurretDecryptor.initUI()
	print("rglx_AncientTurretDecryptor: initUI(): started")
	local res = getResolution()
	local size = vec2(800, 600)

	local menu = ScriptUI()
	local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
	menu:registerWindow(mainWindow, "Decrypt Ancient Technologies")
	mainWindow.caption = "Ancient Technology Decryptor"
	mainWindow.showCloseButton = 1
	mainWindow.moveable = 1

	local vsplit = UIHorizontalSplitter(Rect(mainWindow.size), 10, 10, 0.08)
	inventory = mainWindow:createInventorySelection(vsplit.bottom, 10)

	inventory.onSelectedFunction = "decryptorTargetSelected"
	inventory.onDeselectedFunction = "decryptorTargetUnselected"

	local lister = UIVerticalLister(vsplit.top, 10, 5)
	decryptButton = mainWindow:createButton(Rect(), "Decrypt!", "decryptorActivated")
	lister:placeElementTop(decryptButton)
	decryptButton.active = false
	decryptButton.width = 400

	mainWindow:createFrame(lister.rect)

	lister:setMargin(10, 10, 10, 10)

	print("rglx_AncientTurretDecryptor: initUI(): done")
end


function AncientTurretDecryptor.onShowWindow()
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
end


function AncientTurretDecryptor.renderUI()
	return
end


function AncientTurretDecryptor.refreshUI()
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
	return
end

-- from http://lua-users.org/wiki/FormattingNumbers, by a sam_lie there
function comma_value(amount)
	local formatted = amount
	while true do  
	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	if (k==0) then
		break
	end
	end
	return formatted
end

function AncientTurretDecryptor.decryptionComplete()
	print("rglx_AncientTurretDecryptor: decryptionComplete(): started")
	decryptButton.active = false
	decryptButton.caption = "Done! Enjoy your decrypted item!"
	local ship = Player().craft
	if not ship then return end
	inventory:fill(ship.factionIndex, InventoryItemType.Turret)
	return
	print("rglx_AncientTurretDecryptor: decryptionComplete(): done")
end


function AncientTurretDecryptor.decryptorActivated()
	print("rglx_AncientTurretDecryptor: decryptorActivated(): started")
	decryptButton.active = false
	decryptButton.caption = "Decrypting... This should be instantaneous..."
	local selected = inventory.selected
	if selected then
		invokeServerFunction("decryptTurretFromInventory", selected.index)
	else
		decryptButton.caption = "You didn't select a turret."
		decryptButton.active = true
		return
	end
	print("rglx_AncientTurretDecryptor: decryptorActivated(): done")
end

function AncientTurretDecryptor.getTechLevel()
	-- returns sector current tech level. also adds support for the tech level 51+ blueprinting mod.
	local currentCoords = {}
	currentCoords.x,currentCoords.y = Sector():getCoordinates()
	local currentTechLevel = Balancing_GetTechLevel(currentCoords.x, currentCoords.y)
	if currentTechLevel > 49 then
		if rglx_TL51BPing then
			currentTechLevel = 52
		else
			currentTechLevel = 50
		end
	end
	return currentTechLevel
end


function AncientTurretDecryptor.decryptTurretFromInventory(inventoryIndex)
	if onServer() then -- only run this on the server
		-- relations check
		print("rglx_AncientTurretDecryptor: decryptTurretFromInventory(): invoked. beginning checks...")
		callingPlayerObj = Player(callingPlayer)
		if not CheckFactionInteraction(callingPlayer, AncientTurretDecryptor.interactionThreshold) then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"You're not friendly enough with this faction.")
			return
		end

		-- buyer permissions/sanity check
		local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.AddItems, AlliancePrivilege.SpendResources, AlliancePrivilege.TakeResources)
		if not buyer then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"You don't have permission to use resources and items from your alliance vault.")
			return
		end

		-- sanity check for wether the turret exists and is a turret
		local inventory = buyer:getInventory()
		local indexedTurret = inventory:find(inventoryIndex)
		if not indexedTurret or indexedTurret.itemType ~= InventoryItemType.Turret then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"You can't decrypt this item.")
			return
		end

		-- check if the item in question is ancient
		if not indexedTurret.ancient then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"This item isn't ancient.")
			return
		end

		-- check if the player's docked/close enough
		local errors = {}
		errors[EntityType.Station] = "You must be docked to the station to decrypt Ancient technology."
		errors[EntityType.Ship] = "You must be closer to the ship to decrypt Ancient technology"
		if not CheckPlayerDocked(player, station, errors) then
			return
		end

		-- check if the tech level is high enough here
		if AncientTurretDecryptor.getTechLevel() < indexedTurret.averageTech then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"Tech level here (TL"..AncientTurretDecryptor.getTechLevel()..") isn't high enough.")
			return
		end

		local decryptcost =  math.ceil( (SellableInventoryItem(indexedTurret).price * decryptionCostMultiplier ) / ( 10 * Material(indexedTurret.material.value).costFactor ) )
		local decryptresource = Material(indexedTurret.material.value)

		-- check if they can afford it
		if not buyer:canPayResource(decryptresource,decryptcost) then
			callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",1,"You can't afford to decrypt this. Cost: " .. decryptcost .. " " .. decryptresource.name )
			return
		end

		local receiptString = Format(buyer.name .. " paid ".. decryptcost .." " .. decryptresource.name .. " to decrypt an Ancient item.")
		buyer:payResource(receiptString,indexedTurret.material,decryptcost)

		local decryptedTurret = indexedTurret
		decryptedTurret.ancient = false
		decryptedTurret:addDescription("Decrypted Ancient Technology","Allows blueprinting & fighter usage.")

		inventory:add(decryptedTurret)

		inventory:setAmount(inventoryIndex,inventory:amount(inventoryIndex)-1)

		-- refresh the client's window via onShowWindow()
		invokeClientFunction(player, "decryptionComplete")
		callingPlayerObj:sendChatMessage("Ancient Technology Decryptor",3,"Decryption Complete.")
		print("rglx_AncientTurretDecryptor: decryptTurretFromInventory(): completed.")
	else
		eprint("rglx_AncientTurretDecryptor: decryptTurretFromInventory(): execution attempt on client? this should not happen.")
	end
end
-- makes callable from clients to be run on the server
callable(AncientTurretDecryptor, "decryptTurretFromInventory")

function AncientTurretDecryptor.decryptorTargetSelected()

	-- nothing's selected.
	local selected = inventory.selected
	if not selected then
		decryptButton.active = false
		decryptButton.caption = "Can't decrypt. Nothing selected."
		return
	end

	-- this isn't an item?? somehow?
	if not selected.item then
		decryptButton.active = false
		decryptButton.caption = "Can't decrypt. Not an item."
		return
	end

	-- turret's not an ancient turret
	if not selected.item.ancient then
		decryptButton.active = false
		decryptButton.caption = "Can't decrypt. Not an Ancient item."
		return
	end

	-- check if the tech level's high enough round these parts
	if AncientTurretDecryptor.getTechLevel() < selected.item.averageTech then
		decryptButton.active = false
		decryptButton.caption = "Can't decrypt. Tech level not high enough (TL"..AncientTurretDecryptor.getTechLevel().." here)"
		return
	end

	-- we're not docked.
	local errors = {}
	errors[EntityType.Station] = nil
	errors[EntityType.Ship] = nil
	if not CheckPlayerDocked(Player(), Entity(),errors) then
		decryptButton.active = false
		decryptButton.caption = "Can't decrypt. Not docked."
		return
	end

	-- get our prices in resources
	local decryptCost = math.ceil( (SellableInventoryItem(selected.item).price * decryptionCostMultiplier ) / ( 10 * Material(selected.item.material.value).costFactor ) )
	local decryptResource = Material(selected.item.material.value)

	decryptButton.active = true
	decryptButton.caption = "Decrypt! (".. comma_value(decryptCost) .. " " .. decryptResource.name .. ")"
	print("rglx_AncientTurretDecryptor: decryptorTargetSelected()")
end


function AncientTurretDecryptor.decryptorTargetUnselected()
	decryptButton.active = false
	decryptButton.caption = "Decrypt! (select an item to decrypt)"
	print("rglx_AncientTurretDecryptor: decryptorTargetUnselected()")
end