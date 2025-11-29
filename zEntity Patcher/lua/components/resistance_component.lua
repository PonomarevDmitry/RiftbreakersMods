require( "lua/utils/divergent.lua" )

local M = {}

function M:ResistanceComponentHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    local container = component_ref.resistances
    for key, value in pairs( t ) do
        for item in IterItems( container ) do
            if item.key == key then
                local base = item.value
                base.base, base.current_value = value, value
                goto continue
            end
        end
        do
            local ptr = rawget( container, "__ptr" )
            local new = ptr:ReserveItem()
            local new_ref = divergent_helper( new )
            new_ref.key = key
            local base = new_ref.value
            base.base, base.current_value = value, value
            ptr:InsertItem( new )
        end
        ::continue::
        self:MarkChanges()
    end
end

return M
