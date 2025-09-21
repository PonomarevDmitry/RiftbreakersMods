local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_wrecks_tool' ( tool )

function eraser_wrecks_tool:__init()
    tool.__init(self,self)
end

function eraser_wrecks_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_wrecks_tool", self.entity)
end

function eraser_wrecks_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_wrecks_tool:FindEntitiesToSelect( selectorComponent )

    --local teamWreak = EntityService:GetTeam("wreck")
    --
    --local predicate = {
    --
    --    filter = function(entity)
    --
    --        if ( EntityService:HasComponent( entity, "TeamComponent" ) ) then
    --        
    --            if ( EntityService:GetTeam( entity ) == teamWreak ) then
    --        
    --                return true
    --            end
    --        end
    --
    --        if ( EntityService:HasComponent( entity, "WreckTeamComponent" ) ) then
    --        
    --            return true
    --        end
    --
    --        if ( EntityService:HasComponent( entity, "TypeComponent" ) ) then
    --        
    --            if ( EntityService:CompareType( entity, "wreck" ) ) then
    --                return true
    --            end
    --
    --            if ( EntityService:CompareType( entity, "wreck_small" ) ) then
    --                return true
    --            end
    --
    --            if ( EntityService:CompareType( entity, "wreck_medium" ) ) then
    --                return true
    --            end
    --
    --            if ( EntityService:CompareType( entity, "wreck_large" ) ) then
    --                return true
    --            end
    --        end
    --
    --        return false
    --    end
    --};

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(position, scaleVector)
    local maxVector = VectorAdd(position, scaleVector)

    --local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    local result = {}


    self:FillByTeam(result, "wreck", minVector, maxVector)

    self:FillByWreckTeamComponent(result, minVector, maxVector)

    self:FillByTypeComponent(result, minVector, maxVector)

    

    local selectorPosition = selectorComponent.position

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition( lhs )
        local p2 = EntityService:GetPosition( rhs )
        local d1 = Distance( selectorPosition, p1 )
        local d2 = Distance( selectorPosition, p2 )
        return d1 < d2
    end

    table.sort(result, function(a,b)
        return sorter(result, a, b)
    end)

    return result
end

function eraser_wrecks_tool:FillByTeam(result, teamName, minVector, maxVector)

    local aabb = {}
    aabb.min = minVector
    aabb.max = maxVector

    local tempCollection = FindService:FindEntitiesByTeamInBox( teamName, aabb )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end
end

function eraser_wrecks_tool:FillByWreckTeamComponent(result, minVector, maxVector)

    self.predicateWreckTeamComponent = self.predicateWreckTeamComponent or {

        signature = "WreckTeamComponent",
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, self.predicateWreckTeamComponent )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end
end

function eraser_wrecks_tool:FillByTypeComponent(result, minVector, maxVector)

    self.predicateType = self.predicateType or {

        signature = "TypeComponent",

        filter = function(entity)
    
            if ( EntityService:HasComponent( entity, "TypeComponent" ) ) then
            
                if ( EntityService:CompareType( entity, "wreck" ) ) then
                    return true
                end
    
                if ( EntityService:CompareType( entity, "wreck_small" ) ) then
                    return true
                end
    
                if ( EntityService:CompareType( entity, "wreck_medium" ) ) then
                    return true
                end
    
                if ( EntityService:CompareType( entity, "wreck_large" ) ) then
                    return true
                end
            end
    
            return false
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, self.predicateType )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end
end

function eraser_wrecks_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function eraser_wrecks_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function eraser_wrecks_tool:OnRotate()
end

function eraser_wrecks_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        EntityService:DestroyEntity( entity, "collapse" )
        --EntityService:DissolveEntity( entity, 0.5 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "WrecksEraserToolRequest", false )
    end
end

return eraser_wrecks_tool