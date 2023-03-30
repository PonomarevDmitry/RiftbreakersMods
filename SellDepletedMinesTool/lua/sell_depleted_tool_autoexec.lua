RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)
    
    BuildingService:UnlockBuilding("buildings/tools/sell_depleted")
end)

