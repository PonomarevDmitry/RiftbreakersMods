require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")

ConsoleService:RegisterCommand( "test_log_inventorysystemdata", function( args )

    local inventorySystemDataComponent = EntityService:GetSingletonComponent("InventorySystemDataComponent")

    if ( inventorySystemDataComponent == nil ) then

        LogService:Log("InventorySystemDataComponent is nil")
        return
    end

    local inventorySystemDataComponentRef = reflection_helper( inventorySystemDataComponent )

    LogService:Log(tostring(inventorySystemDataComponentRef))
end)