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

    if ( blueprintName ~= "buildings/main/auto_mines_laying_panel_1a" and
        blueprintName ~= "buildings/main/auto_mines_laying_panel_1b" and

        blueprintName ~= "buildings/main/auto_mines_laying_panel_2a" and
        blueprintName ~= "buildings/main/auto_mines_laying_panel_2b" and

        blueprintName ~= "buildings/main/auto_mines_laying_panel_3a" and
        blueprintName ~= "buildings/main/auto_mines_laying_panel_3b"
    ) then

        return
    end

    local player_id = evt:GetPlayer()

    local mapperName = "AutoMinesLayingPanelOnOperateActionMenu|" .. tostring(player_id)

    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
end)