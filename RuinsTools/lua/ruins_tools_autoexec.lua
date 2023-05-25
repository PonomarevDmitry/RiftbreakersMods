RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/sell_place_ruins")
    BuildingService:UnlockBuilding("buildings/tools/sell_ruins_eraser")
end)