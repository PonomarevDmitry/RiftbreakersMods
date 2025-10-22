if ( is_server and is_client ) then
    return
end

if ( not is_client ) then
    return
end

require("lua/units/units_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")


local CreateMenuEntity = function (entity, menuBlueprintName)

    local menuEntity = nil

    local children = EntityService:GetChildren( entity, true )
    for child in Iter(children) do

        local blueprintName = EntityService:GetBlueprintName( child )
        if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == entity ) then

            menuEntity = child

            break
        end
    end

    if ( menuEntity == nil ) then

        local team = EntityService:GetTeam( entity )
        menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, entity, team)
    end

    if ( menuEntity ~= nil ) then

        local children = EntityService:GetChildren( entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    if ( not EntityService:HasComponent( menuEntity, "LuaComponent" ) ) then

        QueueEvent( "RecreateComponentFromBlueprintRequest", menuEntity, "LuaComponent" )
    end

    --local sizeSelf = EntityService:GetBoundsSize( entity )
    --EntityService:SetPosition( menuEntity, 0, sizeSelf.y + 3, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

local eventHandler = function(evt)

    if ( is_server and is_client ) then
        return
    end

    if ( not is_client ) then
        return
    end

    local entity = evt:GetEntity()

    if ( entity == nil or entity == INVALID_ID or not EntityService:IsAlive( entity ) ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( entity )

    if ( blueprintName == "buildings/resources/liquid_decompressor"
        or blueprintName == "buildings/resources/liquid_decompressor_lvl_2"
        or blueprintName == "buildings/resources/liquid_decompressor_lvl_3"
    ) then

        CreateMenuEntity(entity, "misc/decompressor_liquid_menu")
    end

    
end


RegisterGlobalEventHandler("StartBuildingEvent", eventHandler)

RegisterGlobalEventHandler("BuildingBuildEndEvent", eventHandler)

RegisterGlobalEventHandler("BuildingModifiedEvent", eventHandler)



local attachMenuToAll = function(evt)

    if ( is_server and is_client ) then
        return
    end

    if ( not is_client ) then
        return
    end

    local menuBlueprintName = "misc/decompressor_liquid_menu"

    local entities = FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor" )

    for entity in Iter( entities ) do

        CreateMenuEntity(entity, menuBlueprintName)
    end

    local entities = FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor_lvl_2" )

    for entity in Iter( entities ) do

        CreateMenuEntity(entity, menuBlueprintName)
    end

    local entities = FindService:FindEntitiesByBlueprint( "buildings/resources/liquid_decompressor_lvl_3" )

    for entity in Iter( entities ) do

        CreateMenuEntity(entity, menuBlueprintName)
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", attachMenuToAll)

RegisterGlobalEventHandler("PlayerInitializedEvent", attachMenuToAll)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", attachMenuToAll)