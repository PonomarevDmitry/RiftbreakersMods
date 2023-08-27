RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_picker")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_group")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_group_type")

    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin_group")
    BuildingService:UnlockBuilding("buildings/tools/sell_by_type_seller_ruin_group_type")
end)