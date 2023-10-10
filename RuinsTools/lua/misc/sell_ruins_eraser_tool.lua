local tool_highlight_ruins = require("lua/misc/tool_highlight_ruins.lua")
require("lua/utils/table_utils.lua")

class 'sell_ruins_eraser_tool' ( tool_highlight_ruins )

function sell_ruins_eraser_tool:__init()
    tool_highlight_ruins.__init(self,self)
end

function sell_ruins_eraser_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_ruins_eraser_tool", self.entity)
end

function sell_ruins_eraser_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_ruins_eraser_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_ruins_eraser_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned( entity )

    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function sell_ruins_eraser_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function sell_ruins_eraser_tool:FindEntitiesToSelect( selectorComponent )

    local possibleSelectedEnts = {}

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local tempCollection = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for tempEntity in Iter( tempCollection ) do

        if ( tempEntity ~= nil and IndexOf( possibleSelectedEnts, tempEntity ) == nil ) then
            Insert( possibleSelectedEnts, tempEntity )
        end
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

    local selectedEntities = {}

    for entity in Iter( possibleSelectedEnts ) do

        Insert( selectedEntities, entity )

        ::continue::
    end

    return selectedEntities
end

function sell_ruins_eraser_tool:OnUpdate()

    self:HighlightRuins()
end

function sell_ruins_eraser_tool:OnRotate()
end

function sell_ruins_eraser_tool:OnActivateEntity( entity )

    EntityService:SetGroup( entity, "" )

    BuildingService:BlinkBuilding( entity )

    QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
end

return sell_ruins_eraser_tool