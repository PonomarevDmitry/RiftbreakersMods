require( "lua/utils/table_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local function AssignSlots( self, out_item, t )
    for k, v in pairs( t ) do
        if self:AssignIfTable( out_item, k, v ) then
            goto continue
        end

        if not self:IsType( "string", v, k ) then
            goto continue
        end

        local container, count = out_item[k]:to_container()
        for name in v:gmatch( "([^|]+)" ) do
            for item in IterItems( container, count ) do
                if item:GetValue() == name then
                    goto next
                end
            end
            local new_item = container:CreateItem()
            new_item:SetValue( name )
            self:MarkChanges()
            ::next::

        end

        ::continue::
    end
end

function M:MechEquipmentHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )

    local equipment = component_ref.equipment

    local slots
    for i = 1, equipment.count do
        local item = equipment[i]
        slots = item.slots
    end

    for equipment_slot in Iter( t ) do
        for item in IterItems( slots ) do
            if item.name == equipment_slot.name then
                AssignSlots( self, item, equipment_slot )
                goto continue
            end
        end
        local new_item = slots:create_item()
        AssignSlots( self, new_item, equipment_slot )
        ::continue::
    end
end

return M
