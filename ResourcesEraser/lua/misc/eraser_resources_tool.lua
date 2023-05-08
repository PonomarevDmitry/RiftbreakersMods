local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_resources_tool' ( tool )

function eraser_resources_tool:__init()
    tool.__init(self,self)
end

function eraser_resources_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_resources_tool", self.entity)
end

function eraser_resources_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_resources_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function eraser_resources_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = {}

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local min = VectorSub(position, VectorMulByNumber(boundsSize, self.currentScale))
    local max = VectorAdd(position, VectorMulByNumber(boundsSize, self.currentScale))

    local predicate = {

        signature="ResourceComponent,SelectableComponent,InteractiveComponent,GridMarkerComponent"
    };
    
    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:CompareType( entity, "resource" ) ) then
            goto continue
        end

        local positionTemp = EntityService:GetPosition( entity )

        if ( not ( min.x <= positionTemp.x and positionTemp.x <= max.x ) ) then
            goto continue
        end

        if ( not ( min.z <= positionTemp.z and positionTemp.z <= max.z ) ) then
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

function eraser_resources_tool:AddedToSelection( entity )
    QueueEvent( "SelectEntityRequest", entity )
end

function eraser_resources_tool:RemovedFromSelection( entity )
    QueueEvent( "DeselectEntityRequest", entity )
end

function eraser_resources_tool:OnRotate()
end

function eraser_resources_tool:OnActivateEntity( entity )

    QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )
end

return eraser_resources_tool
