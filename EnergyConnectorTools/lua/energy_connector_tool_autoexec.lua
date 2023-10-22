RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_1")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_2")
    BuildingService:UnlockBuilding("buildings/energy/energy_connector_tool_3")
end)