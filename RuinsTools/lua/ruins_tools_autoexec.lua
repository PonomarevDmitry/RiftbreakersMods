RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/ruins_eraser")
    BuildingService:UnlockBuilding("buildings/tools/sell_place_ruins")
end)