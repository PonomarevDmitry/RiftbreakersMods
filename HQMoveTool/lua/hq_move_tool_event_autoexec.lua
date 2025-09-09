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

    BuildingService:EnableSellOption( entity )

end)