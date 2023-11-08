RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/building_search_1_select")

    BuildingService:UnlockBuilding("buildings/tools/building_search_2_clear")
end)