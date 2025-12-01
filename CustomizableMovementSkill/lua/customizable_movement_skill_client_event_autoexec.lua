if ( is_server and is_client ) then
    return
end

if ( not is_client ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMenuEvent", function(evt)

    if ( is_server and is_client ) then
        return
    end

    if ( not is_client ) then
        return
    end

    local entity = evt:GetEntity()

    if ( not EntityService:IsAlive(entity) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( blueprintName ~= "buildings/main/customizable_movement_skill_panel_1" and
        blueprintName ~= "buildings/main/customizable_movement_skill_panel_1b" and

        blueprintName ~= "buildings/main/customizable_movement_skill_panel_2" and
        blueprintName ~= "buildings/main/customizable_movement_skill_panel_2b" and

        blueprintName ~= "buildings/main/customizable_movement_skill_panel_3" and
        blueprintName ~= "buildings/main/customizable_movement_skill_panel_3b"
    ) then

        return
    end

    local player_id = evt:GetPlayer()

    local mapperName = "CustomizableMovementSkillPanelOnOperateActionMenu|" .. tostring(player_id)

    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
end)