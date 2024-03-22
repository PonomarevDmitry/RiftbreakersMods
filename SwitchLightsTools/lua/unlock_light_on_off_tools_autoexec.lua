RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/tools/light_1_on")
    BuildingService:UnlockBuilding("buildings/tools/light_2_off")
end)