require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

local supported_research_list = {

    {
        ["name"] = "gui/menu/research/name/turrets_cluster_mods_scanner_turret_standard_item",
        ["research_category"] = "gui/menu/research/category_weapons_equipment",
        ["research_name"] = "gui/menu/research/name/consumable_scanner_turret_standard",
    },
}

local turrets_cluster_unlock_researches_autoexec = function(evt)

    local researchComponent = EntityService:GetSingletonComponent( "ResearchSystemDataComponent" )
    if ( researchComponent == nil ) then
        return nodes
    end

    local researchComponentRef = reflection_helper( researchComponent )

    local categories = researchComponentRef.research

    for i=1,categories.count do

        local category = categories[i]

        local category_nodes = category.nodes
        for j=1,category_nodes.count do

            local node = category_nodes[j]

            for _, item in ipairs(supported_research_list) do

                if ( node.research_name == item.research_name and category.category == item.research_category ) then

                    PlayerService:UnhideResearch( item.name )
                    PlayerService:EnableResearch( item.name )
                end
            end
        end
    end
end

RegisterGlobalEventHandler("PlayerCreatedEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerInitializedEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)

RegisterGlobalEventHandler("PlayerControlledEntityChangeEvent", function(evt)

    turrets_cluster_unlock_researches_autoexec(evt)
end)