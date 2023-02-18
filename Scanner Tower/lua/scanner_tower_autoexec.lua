RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/defense/tower_scanner")
end)

