-- require( "lua/utils/reflection.lua" )
require( "lua/utils/divergent.lua" )
local M = {}

local field_map = {
    ["cooldown"] = function( self, component_ref, value )
        local bp = ResourceManager:GetBlueprint( self.bp_name )
        local component_runtime_ref = divergent_helper( bp:GetComponent( "InventoryItemRuntimeDataComponent" ) )
        if not component_runtime_ref then
            self:Log( "Failed to set cooldown" )
            self:MarkFails()
            return
        end
        component_runtime_ref.cooldown = value
        component_ref.cooldown = value
        self:MarkChanges( 2 )
    end
 }

function M:InventoryItemDescHandler( bp_component, t, component )
    local component_ref = divergent_helper( bp_component )

    for field, value in pairs( t ) do
        if not self:Exist( component_ref[field], field ) then
            goto continue
        end
        local invoke = field_map[field]
        if invoke then
            invoke( self, component_ref, value, component )
        else
            component_ref[field] = value
            self:MarkChanges()
        end
        ::continue::
    end
end

return M
