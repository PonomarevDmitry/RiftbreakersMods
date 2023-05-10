local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_ruins_tool' ( tool )

function eraser_ruins_tool:__init()
    tool.__init(self,self)
end

function eraser_ruins_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_ruins_tool", self.entity)

    self.previousMarkedRuins = {}
    self.radiusShowRuins = 100.0
end

function eraser_ruins_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_ruins_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function eraser_ruins_tool:FindEntitiesToSelect( selectorComponent )

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

function eraser_ruins_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned( entity )

    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
    end
end

function eraser_ruins_tool:RemovedFromSelection( entity )

    EntityService:RemoveMaterial( entity, "selected" )
end

function eraser_ruins_tool:OnUpdate()
    
    local ruinsList = self:FindBuildingRuins()
    
    self.previousMarkedRuins = self.previousMarkedRuins or {}
    
    for entity in Iter( self.previousMarkedRuins ) do
    
        -- If the building is not included in the new list
        if ( IndexOf( ruinsList, entity ) == nil and IndexOf( self.selectedEntities, entity ) == nil ) then
            self:RemovedFromSelection( entity )
        end
    end
    
    for entity in Iter( ruinsList ) do
        
        local skinned = EntityService:IsSkinned( entity )
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
        end
    end
    
    self.previousMarkedRuins = ruinsList
end

function eraser_ruins_tool:FindBuildingRuins()

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

function eraser_ruins_tool:OnActivateEntity( entity )

    EntityService:SetGroup( entity, "" )
        
    BuildingService:BlinkBuilding( entity )
        
    QueueEvent( "DissolveEntityRequest", entity, 1.0, 0 )
end

function eraser_ruins_tool:OnRelease()
    
    if ( self.previousMarkedRuins ~= nil) then
        for ent in Iter( self.previousMarkedRuins ) do
            self:RemovedFromSelection( ent )
        end
    end
    self.previousMarkedRuins = {}

    tool.OnRelease(self)
end

function eraser_ruins_tool:OnRotate()
end

return eraser_ruins_tool
