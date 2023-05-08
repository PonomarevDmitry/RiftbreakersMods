RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_picker")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_group")
end)

