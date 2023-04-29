RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_picker")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller")
end)

