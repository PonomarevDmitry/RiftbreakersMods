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

    if ( mapperName ~= "HQMoveToolEnableSellOption" ) then
        return
    end

    local entity = evt:GetEntity()

    -- Clear Build Costs
    local component = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( component ~= nil ) then

        local componentRef = reflection_helper( component )

        if ( componentRef.build_costs ~= nil and componentRef.build_costs.resource ~= nil ) then

            local container = rawget( componentRef.build_costs.resource, "__ptr" );

            if ( container ~= nil ) then

                local itemsCount = container:GetItemCount()

                for i=itemsCount,1,-1 do
                    container:EraseItem(i-1)
                end
            end
        end
    end

    BuildingService:EnableSellOption( entity )

end)