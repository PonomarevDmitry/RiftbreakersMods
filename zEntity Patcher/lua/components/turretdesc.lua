require( "lua/utils/type_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local type_to_number = {
    ["building"] = 1,
    ["decorations"] = 2,
    ["defense"] = 3,
    ["energy"] = 4,
    ["ground_unit"] = 5,
    ["ground_unit_small"] = 6,
    ["ground_unit_medium"] = 7,
    ["ground_unit_large"] = 8,
    ["headquarters"] = 9,
    ["ground_unit_artillery"] = 10,
    ["main"] = 11,
    ["player"] = 12,
    ["prop"] = 13,
    ["resource"] = 14,
    ["shield"] = 15,
    ["spawner"] = 16,
    ["tower"] = 17,
    ["water"] = 18,
    ["wall"] = 19,
    ["quelver"] = 20,
    ["air_unit"] = 21,
    ["drones"] = 22,
    ["invisible"] = 23,
    ["flora"] = 24,
    ["crystal"] = 25,
    ["light"] = 26,
    ["not_move_to_target"] = 27,
    ["scannable"] = 28,
    ["ignore_as_target"] = 29,
    ["wreck_small"] = 30,
    ["wreck_medium"] = 31,
    ["wreck_large"] = 32,
    ["prop_alien"] = 33,
    ["cavern_wall"] = 34,
    ["food"] = 35,
    ["spikybulb"] = 36,
    ["energy_connector"] = 37,
    ["boss"] = 38
}

local function SetType( self, component, field, str )
    local value = 0
    for it in str:gmatch( "([^|]+)" ) do
        local target = type_to_number[it]
        if target then
            local bit = 2 ^ target
            if math.floor( value / bit ) % 2 == 0 then
                value = value + bit
            end
        else
            self:Log( ("Unknow type '%s'"):format( it ) )
            self:MarkFails()
        end
    end
    component[field] = value
    self:MarkChanges()
end

local function SetTarget( self, component, field, str )
    local target = component[field]
    local map = target.type_map
    local vec = target.type_vec

    if type( str ) ~= "string" then
        self:Log( ("Expected string format for target, instead got '%s' "):format( type( str ) ) )
        self:MarkFails()
        return
    end

    local value = 0
    -- local seen = {}
    for it in str:gmatch( "([^|]+)" ) do
        local key = type_to_number[it]
        if key ~= nil then
            for item in IterItems( map ) do
                if item.key == key then
                    item.value = value
                    goto next
                end
            end
            map:pair_create_item( key, value )
            ::next::
            -- seen[key] = true
            self:MarkChanges()
            value = value + 1
        else
            self:Log( ("Type passed key '%s' is 'nil'"):format( it ) )
            self:MarkFails()
        end
    end

    local count = map.count
    -- for i = 1, count do
    --     local item = map[i]
    --     if not seen[item.key] then
    --         table.remove( map, i )
    --     end
    -- end

    local rank = {}
    for item in IterItems( map, count ) do
        rank[#rank + 1] = {
            key = tostring( item.key ),
            value = item.value
        }
    end

    table.sort( rank, function( a, b )
        return a.value < b.value
    end )

    local container = rawget( vec, "__ptr" )
    while vec.count < count do
        container:CreateItem()
    end

    for item, i in IterItems( container, count ) do
        item:SetValue( rank[i + 1].key )
    end
end

local switch = {
    ["aim_volume"] = vector_helper,
    ["aiming_offset"] = vector_helper,
    ["target"] = SetTarget,
    ["scale"] = vector_helper,
    ["type"] = SetType

}

function M:TurretHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        if not self:Exist( component_ref[field], field ) then
            goto continue
        end
        local invoke = switch[field]
        if invoke then
            invoke( self, component_ref, field, value )
            goto continue
        end
        component_ref[field] = value
        self:MarkChanges()
        ::continue::
    end
end

return M
