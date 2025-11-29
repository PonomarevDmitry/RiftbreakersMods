require( "lua/utils/type_utils.lua" )
require( "lua/utils/divergent.lua" )

local M = {}

local switch = {}
switch.Shape = {}

local function Assign( self, out_item, t )
    for k, v in pairs( t ) do
        if self:AssignIfTable( out_item, k, v ) then
            goto continue
        end

        if not self:IsType( "table", v, k ) then
            goto continue
        end

        vector_helper( self, out_item, k, v )

        ::continue::
    end
end

function switch.Shape:Sphere( container, t )
    local seen = {}
    for i = 1, container.count do
        local item = container[i]
        if item:type_name() == "PhysicsSphereShape" then
            item.r = t[i].r
            seen[i] = true
            self:MarkChanges()
        end
    end

    for i, content in pairs( t ) do
        if not seen[i] then
            local new_item = container:create_item( "PhysicsSphereShape" )
            new_item.r = content.r
            self:MarkChanges()
        end
    end
end

function switch.Shape:Capsule( container, t )
    local seen = {}
    for i = 1, container.count do
        local item = container[i]
        if item:type_name() == "PhysicsCapsuleShape" then
            Assign( self, item, t[i] )
            seen[i] = true
        end
    end

    for i, content in ipairs( t ) do
        if not seen[i] then
            local new_item = container:create_item( "PhysicsCapsuleShape" )
            Assign( self, new_item, content )
        end
    end
end

function switch.Shape:Box( container, t )
    local seen = {}
    for i = 1, container.count do
        local item = container[i]
        if item:type_name() == "PhysicsBoxShape" then
            Assign( self, item, t[i] )
            seen[i] = true
        end
    end

    for i, content in ipairs( t ) do
        if not seen[i] then
            local new_item = container:create_item( "PhysicsBoxShape" )
            Assign( self, new_item, content )
        end
    end
end

function switch:Shapes( component, t )
    local container = component.Shapes

    for name, shapes in pairs( t ) do
        local fn = switch.Shape[name]
        if fn then
            fn( self, container, shapes )
        else
            self:Log( ("Unknow shape '%s'"):format( name ) )
            self.MarkFails()
        end
    end
end

function M:GridCullerHandler( bp_component, t )
    local component_ref = divergent_helper( bp_component )
    for field, value in pairs( t ) do

        if self:AssignIfTable( component_ref, field, value ) then
            goto continue
        end

        local invoke = switch[field]
        if invoke then
            invoke( self, component_ref, value )
            goto continue
        end

        ::continue::
    end

end

return M
