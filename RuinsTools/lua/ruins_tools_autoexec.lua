RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/sell_1_place_ruins")
    BuildingService:UnlockBuilding("buildings/tools/sell_1_ruins_eraser")
end)