require( "lua/utils/type_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local function converter_helper( self, out_item, t )
    for k, v in pairs( t ) do
        if self:AssignIfTable( out_item, k, v ) then
            goto continue
        end

        if not self:IsType( "table", v, k ) then
            goto continue
        end
        ::continue::
    end
end

function M:ResourceConverterDescHandler( bp_component, t )
    -- local component_ref = reflection_helper( bp_component )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do

        if type( component_ref[field] ) ~= "table" then
            component_ref[field] = value
            self:MarkChanges()
            goto continue
        end

        if not self:IsType( "table", value, field ) then
            goto continue
        end

        if field ~= "in" and field ~= "out" then
            LogService:Log( ("%s Expected 'in' or 'out', instead got %s %s"):format( self.mod_name, field, self.bp_name ) )
            goto continue
        end

        local container = component_ref[field]
        for i = 1, container.count do
            local item = container[i]
            local id = item.resource.resource.id
            if value[id] ~= nil then
                converter_helper( self, item, value[id] )
            end
        end
        ::continue::
    end
end

return M
