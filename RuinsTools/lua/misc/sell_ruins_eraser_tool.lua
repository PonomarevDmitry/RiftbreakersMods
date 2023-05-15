local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'sell_ruins_eraser_tool' ( tool )

function sell_ruins_eraser_tool:__init()
    tool.__init(self,self)
end

function sell_ruins_eraser_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_sell_ruins_eraser_tool", self.entity)

    self.previousMarkedRuins = {}
    self.radiusShowRuins = 100.0
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

    local boundsSize = { x=1.0, y=1.0, z=1.0 }

    local min = VectorSub(position, VectorMulByNumber(boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(boundsSize , self.currentScale - 0.5))

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

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    for ruinEntity in Iter( self.previousMarkedRuins ) do

        if ( IndexOf( ruinsList, ruinEntity ) == nil and IndexOf( self.selectedEntities, ruinEntity ) == nil ) then
            self:RemovedFromSelection( ruinEntity )
        end
    end

    for ruinEntity in Iter( ruinsList ) do

        local skinned = EntityService:IsSkinned( ruinEntity )
        if ( skinned ) then
            EntityService:SetMaterial( ruinEntity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( ruinEntity, "selector/hologram_current", "selected")
        end
    end

    self.previousMarkedRuins = ruinsList
end

function sell_ruins_eraser_tool:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local buildings = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for entity in Iter( buildings ) do

        if ( IndexOf( self.selectedEntities, entity ) ~= nil ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function sell_ruins_eraser_tool:OnRotate()
end

function sell_ruins_eraser_tool:OnActivateEntity( entity )

    EntityService:SetGroup( entity, "" )

    BuildingService:BlinkBuilding( entity )

    QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
end

function sell_ruins_eraser_tool:OnRelease()

    if ( self.previousMarkedRuins ~= nil) then
        for ent in Iter( self.previousMarkedRuins ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then

        tool.OnRelease(self)
    end
end

return sell_ruins_eraser_tool