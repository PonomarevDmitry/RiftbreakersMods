require( "lua/utils/type_utils.lua" )
require( "lua/utils/table_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local function costs_helper( self, out_item, t )
    for field, v in pairs( t ) do
        if self:AssignIfTable( out_item, field, v ) then
            goto continue
        end

        if not self:IsType( "table", v, field ) then
            goto continue
        end

        local container = out_item[field]
        for key, value in pairs( v ) do
            for item in IterItems( container ) do
                if item.key == key then
                    item.value = value
                    goto next
                end
            end
            container:pair_create_item( key, value )
            ::next::
            self:MarkChanges()
        end

        ::continue::
    end
end

local function buildingdesc_cost_handler( self, component, field, t )
    local container = component[field]
    for _, it in ipairs( t ) do

        for i = 1, container.count do
            local item = container[i]
            if item.name == it.name then
                costs_helper( self, item, it.data[i] or it.data )
                goto continue
            end
        end

        -- create ?
        self:Log( ("Costs name '%s' not found "):format( it.name ) )

        ::continue::
    end
end

local function VectorString( self, component, field, t )
    local container, count = component[field]:to_container()
    for k in Iter( t ) do
        for item in IterItems( container, count ) do
            if item:GetValue() == k then
                goto continue
            end
        end

        local new_item = container:CreateItem()
        new_item:SetValue( k )
        self:MarkChanges()

        ::continue::
    end
end

local switch = {
    ["overrides"] = hash_helper,
    ["exclude_terrain_types"] = hash_helper,
    ["resource_requirement"] = VectorString,
    ["costs"] = buildingdesc_cost_handler,
    ["build_cost"] = ResourceBasket,
    ["cost"] = ResourceBasket,
    ["current_cost"] = ResourceBasket,
    ["current_build_cost"] = ResourceBasket,
    ["build_costs"] = ResourceBasket,
    __default = function( self, item, field, value )
        item[field] = value
        self:MarkChanges()
    end
}

function M:BuildingDescHandler( bp_component, t, component )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        if not component_ref[field] then
            self:Log( "Unable to get " .. field )
            self:MarkFails()
            goto continue
        end

        (switch[field] or switch.__default)( self, component_ref, field, value )

        ::continue::
    end
end

return M
