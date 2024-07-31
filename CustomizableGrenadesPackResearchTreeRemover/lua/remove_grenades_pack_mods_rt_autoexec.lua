require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

local removeResearchTree = function(categoryName)

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    if ( researchComponent == nil ) then
        return
    end

    local researchComponentRef = reflection_helper( researchComponent )

    local categories = researchComponentRef.research

    for i=1,categories.count do

        local category = categories[i]

        if ( category.category == categoryName ) then

            LogService:Log("removeResearchTree category '" .. categoryName .. "' FOUNDED and REMOVED.")

            local categoryContainer = researchComponent:GetField("research"):ToContainer()

            categoryContainer:EraseItem( i - 1 )

            return
        end
    end
end

local removeResearchTreeEvent = function(evt)

    local playerId = evt:GetPlayerId()

    local player = PlayerService:GetPlayerControlledEnt( playerId )

    if ( player == nil or player == INVALID_ID ) then
        return
    end
    
    local categoryName = "gui/menu/research/category_grenades_pack_mods"

    removeResearchTree(categoryName)
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    removeResearchTreeEvent(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    removeResearchTreeEvent(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    removeResearchTreeEvent(evt)
end)