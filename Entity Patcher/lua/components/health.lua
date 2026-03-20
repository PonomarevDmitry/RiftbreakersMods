-- require( "lua/utils/reflection.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local health_operations = {
    ["="] = function( self, component, value )
        component.max_health = math.max( 1, value )
        component.health = math.max( 1, value )
        self:MarkChanges( 2 )
    end,
    ["+"] = function( self, component, value )
        component.max_health = math.max( 1, component.max_health + value )
        component.health = math.max( 1, component.health + value )
        self:MarkChanges( 2 )
    end,
    ["-"] = function( self, component, value )
        component.max_health = math.max( 1, component.max_health - value )
        component.health = math.max( 1, component.health - value )
        self:MarkChanges( 2 )
    end,
    ["*"] = function( self, component, value )
        component.max_health = math.max( 1, component.max_health * value )
        component.health = math.max( 1, component.health * value )
        self:MarkChanges( 2 )
    end,
    ["/"] = function( self, component, value )
        if value == 0 then
            LogService:Log( self.mod_name .. " Division by zero on " .. self.bp_name )
            self:MarkFails()
        else
            component.max_health = math.max( 1, component.max_health / value )
            component.health = math.max( 1, component.health / value )
            self:MarkChanges( 2 )
        end
    end
 }

local switch = {
    ["health2"] = health_operations["="],
    ["health+"] = health_operations["+"],
    ["health-"] = health_operations["-"],
    ["health*"] = health_operations["*"],
    ["health/"] = health_operations["/"],
    __default = function( self, component, value, field )
        if self:Exist( component[field], field ) then
            component[field] = value
            self:MarkChanges()
        end
    end
 }

function M:HealthHandler( bp_component, t )
    if type( t ) ~= "table" then
        self:Log( "Expected table format" )
        self:MarkFails()
        return
    end
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do
        (switch[field] or switch.__default)( self, component_ref, value, field )

        -- ::continue::
    end
end

return M
