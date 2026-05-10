if ( not is_server ) then
    return
end

require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/database_utils.lua")

RegisterGlobalEventHandler("OperateActionMapperRequest", function(evt)

    if ( not is_server ) then
        return
    end

    local mapperName = evt:GetMapperName()

    if ( mapperName == "UnitTypeChangeToInvisibleRequest" ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end


        local currentType = EntityService:GetType(entity) or ""

        if ( string.len(currentType) > 0 ) then

            currentType = currentType .. "|"
        end

        currentType = currentType .. "invisible"

        EntityService:ChangeType( entity, currentType )





        local markerBlueprintName = "effects/unit_type_changer_tool/unit_type_changer_ignore"

        local childreen = EntityService:GetChildren(entity, true)

        for childEntity in Iter( childreen ) do

            local blueprintName = EntityService:GetBlueprintName(childEntity)

            if ( blueprintName == markerBlueprintName ) then
                return
            end
        end

        local size = EntityService:GetBoundsSize( entity )

        local markEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, entity )

        local newPosition = {}

        newPosition.x = 0
        newPosition.y = size.y + 4
        newPosition.z = 0

        EntityService:SetPosition( markEntity, newPosition )

        return
    end



    if ( mapperName == "UnitTypeRemoveInvisibleRequest" ) then

        local entity = evt:GetEntity()

        if ( not EntityService:IsAlive(entity) ) then
            return
        end


        local currentType = EntityService:GetType(entity) or ""

        currentType = string.gsub( currentType, "|invisible", "" )

        currentType = string.gsub( currentType, "invisible|", "" )

        currentType = string.gsub( currentType, "invisible", "" )

        currentType = string.gsub( currentType, "||", "|" )

        currentType = string.gsub( currentType, "^[|]*(.-)[|]*$", "%1" )

        EntityService:ChangeType( entity, currentType )





        local markerBlueprintName = "effects/unit_type_changer_tool/unit_type_changer_ignore"

        local childreen = EntityService:GetChildren(entity, true)

        for childEntity in Iter( childreen ) do

            local blueprintName = EntityService:GetBlueprintName(childEntity)

            if ( blueprintName == markerBlueprintName ) then

                EntityService:RemoveEntity( childEntity )
            end
        end

        return
    end

end)