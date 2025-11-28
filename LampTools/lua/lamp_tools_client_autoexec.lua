if ( not is_client ) then
    return
end

require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/replace_lamp_tool_last_selected_blueprints_utils.lua")

RegisterGlobalEventHandler("ChangeSelectorRequest", function(evt)

    if ( not is_client ) then
        return
    end

    local blueprintName = evt:GetBlueprint() or ""
    if ( blueprintName == "" or blueprintName == nil ) then
        return
    end

    local selector = evt:GetEntity()
    if ( selector == nil or selector == INVALID_ID ) then
        return
    end
    
    local playerReferenceComponent = EntityService:GetComponent(selector, "PlayerReferenceComponent")
    if ( playerReferenceComponent == nil ) then
        return
    end

    local playerReferenceComponent = reflection_helper( playerReferenceComponent )
    local playerId = playerReferenceComponent.player_id

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper(buildingDesc)
    if ( buildingDescRef.category == "tools" ) then
        return
    end

    local lowName = BuildingService:FindLowUpgrade( blueprintName )
    if ( lowName ~= "base_lamp" and lowName ~= "crystal_lamp" ) then
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        return
    end

    local buildingComponent = blueprint:GetComponent("BuildingComponent")
    if ( buildingComponent == nil ) then
        return
    end

    if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
        return
    end

    local parameterName = "$selected_lamp_blueprint"

    if ( selector and selector ~= INVALID_ID ) then

        local selectorDB = EntityService:GetOrCreateDatabase( selector )
        if ( selectorDB ) then
            selectorDB:SetString(parameterName, blueprintName)
        end

        local playerId = PlayerService:GetPlayerForEntity( selector )

        if ( playerId ~= nil and playerId ~= -1 ) then

            local globalPlayerEntity = PlayerService:GetGlobalPlayerEntity( playerId )

            if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

                local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

                if ( globalPlayerEntityDB ) then
                    globalPlayerEntityDB:SetString( parameterName, blueprintName )
                end

                if not ( is_server and is_client ) then

                    local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. parameterName .. "|" .. blueprintName

                    QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
                end
            end
        end
    end

    local parameterName = "$replace_lamp_all.last_selected_buildings"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end)