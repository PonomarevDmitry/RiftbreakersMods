-- require( "lua/utils/reflection.lua" )
require( "lua/utils/type_utils.lua" )
require( "lua/utils/divergent.lua" )
local M = {}

local helpers = {}

function helpers:helper( out_item, field, value )
    if out_item[field] == nil then
        self:MarkFails()
        goto continue
    end

    if type( out_item[field] ) ~= "table" then
        out_item[field] = value
        self:MarkChanges()
        goto continue
    end

    if type( value ) ~= "table" then
        LogService:Log( ("%s expected table format for vector and containers %s "):format( self.mod_name, self.bp_name ) )
        goto continue
    end

    if out_item:is_container( field ) then
        self:Log( ("Field is a container '%s'"):format( field ) )
        -- local container = out_item[field]
        -- for k, v in pairs( value ) do
        --     for i = 1, container.count do
        --         local item = container[i]
        --         helpers.helper( self, item, k, v )
        --     end
        -- end
        goto continue
    else
        vector_helper( self, out_item, field, value )
    end

    ::continue::
end

function M:DefaultHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        helpers.helper( self, component_ref, field, value )
    end

end

return M
