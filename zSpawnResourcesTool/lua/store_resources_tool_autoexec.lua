RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/store_resources")
end)