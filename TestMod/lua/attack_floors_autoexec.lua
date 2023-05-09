RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    local player = PlayerService:GetPlayerControlledEnt( 0 )

    if ( player == nil ) then
        return
    end

    local skillName = "items/skills/wall_pulse_item"

    local itemCount = ItemService:GetItemCount( player, skillName )

    --LogService:Log("skillName " .. skillName .. " itemCount " .. tostring(itemCount))

    if ( itemCount > 0 ) then
        return
    end

    PlayerService:AddItemToInventory( 0, skillName )
    
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_acid_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_acid_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_acid_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_acid_4x4")
    --
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_cryo_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_cryo_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_cryo_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_cryo_4x4")
    --
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_energy_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_energy_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_energy_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_energy_4x4")
    --
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_fire_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_fire_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_fire_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_fire_4x4")
    --
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_area_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_area_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_area_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_area_4x4")
    --
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_physical_1x1")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_physical_2x2")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_physical_3x3")
    --BuildingService:UnlockBuilding("buildings/decorations/attack_floor_physical_4x4")
end)

