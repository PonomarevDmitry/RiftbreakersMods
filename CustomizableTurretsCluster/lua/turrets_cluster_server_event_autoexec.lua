if ( is_server and is_client ) then
    return
end

if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( is_server and is_client ) then
        return
    end

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    local stringNumber = string.find( mapperName, "TurretsClusterPanelOnOperateActionMenu" )

    if ( stringNumber == 1 ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end

        local splitArray = Split( mapperName, "|" )

        if ( #splitArray ~= 2 ) then
            return
        end

        local playerIdStr = splitArray[2]

        local playerId = tonumber(playerIdStr)
        if ( playerId == nil ) then
            return
        end

        local player = PlayerService:GetPlayerControlledEnt(playerId)
        if ( player == INVALID_ID or player == nil ) then
            return
        end
        
        local entityDatabase = EntityService:GetDatabase( entity )
        local blueprintDatabase = EntityService:GetBlueprintDatabase( entity ) or entityDatabase

        entityDatabase:SetInt("$current_player_id", playerId)

        local skillName = blueprintDatabase:GetStringOrDefault("skill_name", "items/skills/turrets_cluster_1_item")

        local turretsClusterItem = ItemService:GetFirstItemForBlueprint( player, skillName )
        if ( turretsClusterItem == INVALID_ID ) then
            turretsClusterItem = ItemService:AddItemToInventory( player, skillName )
        end

        if ( turretsClusterItem == INVALID_ID ) then
            return
        end

        local database = EntityService:GetOrCreateDatabase( turretsClusterItem )
        if ( database == nil ) then
            return
        end

        local modDelta = blueprintDatabase:GetIntOrDefault("mod_delta", 0)

        local equipmentComponent = EntityService:GetComponent(entity, "EquipmentComponent")
        if ( equipmentComponent ~= nil ) then

            local equipment = reflection_helper( equipmentComponent ).equipment[1]

            local slots = equipment.slots
            for i=1,slots.count do

                local slot = slots[i]

                local keyName = "turrets_cluster_MOD_" .. tostring(i + modDelta)

                local itemBlueprintName = ""

                if ( database:HasString(keyName) ) then
                    itemBlueprintName = database:GetStringOrDefault(keyName, "") or ""
                end

                if ( itemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", itemBlueprintName ) ) then

                    local item = ItemService:GetFirstItemForBlueprint( entity, itemBlueprintName )

                    if ( item == INVALID_ID ) then
                        item = ItemService:AddItemToInventory( entity, itemBlueprintName )
                    end

                    if ( item ~= INVALID_ID ) then

                        QueueEvent( "EquipmentChangeRequest", entity, slot.name, 0, item )
                    else

                        QueueEvent( "EquipmentChangeRequest", entity, slot.name, 0, INVALID_ID )
                    end
                else

                    QueueEvent( "EquipmentChangeRequest", entity, slot.name, 0, INVALID_ID )
                end
            end
        end

        EntityService:CreateComponent( entity, "NetReplicateNextFrameComponent")

        return
    end
end)
