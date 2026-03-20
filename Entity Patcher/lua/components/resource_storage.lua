require( "lua/utils/divergent.lua" )

local M = {}

function M:ResourceStorageHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )

    for field, value in pairs( t ) do
        if component_ref[field] == nil then
            goto continue
        end

        if type( component_ref[field] ) ~= "table" then
            component_ref[field] = value
        end

        if type( value ) ~= "table" then
            goto continue
        end

        local container = component_ref[field]
        for i = 1, container.count do
            -- local item = container[i]

        end
        ::continue::
    end

end

return M
