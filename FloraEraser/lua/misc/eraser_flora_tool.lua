local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_flora_tool' ( tool )

function eraser_flora_tool:__init()
    tool.__init(self,self)
end

function eraser_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_flora_tool", self.entity)
end

function eraser_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_flora_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function eraser_flora_tool:FindEntitiesToSelect( selectorComponent )

    local predicate = {

        signature="TypeComponent",

        filter = function(entity)

            if ( EntityService:CompareType( entity, "flora" ) ) then
                return true
            end

            return false
        end
    };

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local minVector = VectorSub(position, VectorMulByNumber(boundsSize, self.currentScale))
    local maxVector = VectorAdd(position, VectorMulByNumber(boundsSize, self.currentScale))

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    local possibleSelectedEnts = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:CompareType( entity, "flora" ) ) then
            goto continue
        end

        local positionTemp = EntityService:GetPosition( entity )

        if ( not ( minVector.x <= positionTemp.x and positionTemp.x <= maxVector.x ) ) then
            goto continue
        end

        if ( not ( minVector.z <= positionTemp.z and positionTemp.z <= maxVector.z ) ) then
            goto continue
        end

        Insert( possibleSelectedEnts, entity )

        ::continue::
    end

    local selectorPosition = selectorComponent.position
    
    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2 
    end

    table.sort(possibleSelectedEnts, function(a,b) 
        return sorter(possibleSelectedEnts, a, b) 
    end)
    
    return possibleSelectedEnts
end

function eraser_flora_tool:AddedToSelection( entity )
end

function eraser_flora_tool:RemovedFromSelection( entity )
end

function eraser_flora_tool:OnRotate()
end

function eraser_flora_tool:OnActivateEntity( entity )

    QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )
end

return eraser_flora_tool
