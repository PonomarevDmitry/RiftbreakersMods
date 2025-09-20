local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'fertilizer_flora_tool' ( tool )

function fertilizer_flora_tool:__init()
    tool.__init(self,self)
end

function fertilizer_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_fertilizer_flora_tool", self.entity)

    self.effect_blueprint = self.data:GetStringOrDefault("fertilize_effect", "")
end

function fertilizer_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function fertilizer_flora_tool:FindEntitiesToSelect( selectorComponent )

    local selectorPosition = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    local result = {}

    self:FillFloraByTypeComponent(result, minVector, maxVector)

    -- VegetationLifecycleEnablerComponent and VegetationLifecycleComponent only on server
    if ( is_server ) then
        self:FillFloraByVegetationLifecycleEnablerComponent(result, minVector, maxVector)
    end

    self:FillFloraByVegetationDummyRoot(result, minVector, maxVector)



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

function fertilizer_flora_tool:FillFloraByTypeComponent(result, minVector, maxVector)

    self.predicateType = self.predicateType or {

        signature = "TypeComponent",

        filter = function(entity)

            local blueprintName = EntityService:GetBlueprintName(entity)

            if ( EntityService:CompareType( entity, "flora" ) ) then
                return true
            end

            if ( string.find(blueprintName, "units/ground/cosmic_crystal_creeper_branch" ) ~= nil ) then

                return true
            end

            if ( string.find(blueprintName, "units/ground/crystal_creeper_branch" ) ~= nil ) then

                return true
            end

            if ( string.find(blueprintName, "units/ground/creeper_branch" ) ~= nil ) then

                return true
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

function fertilizer_flora_tool:FillFloraByVegetationLifecycleEnablerComponent(result, minVector, maxVector)

    self.predicateVegetationLifecycle = self.predicateVegetationLifecycle or {
        signature = "VegetationLifecycleEnablerComponent"
    }

    tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, self.predicateVegetationLifecycle )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        local enablerComponent = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( enablerComponent == nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end
end

function fertilizer_flora_tool:FillFloraByVegetationDummyRoot(result, minVector, maxVector)

    local entities = FindService:FindEntitiesByBlueprintInBox( "props/base/vegetation_dummy_root", minVector, maxVector )

    for entity in Iter( entities ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert(result, entity)

        ::labelContinue::
    end
end

function fertilizer_flora_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/active", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/active", "selected" )
        end
    end
end

function fertilizer_flora_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function fertilizer_flora_tool:OnRotate()
end

function fertilizer_flora_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        if ( EntityService:HasComponent( entity, "VegetationLifecycleEnablerComponent" ) ) then

            EntityService:RemoveComponent(entity, "VegetationLifecycleComponent")

            EntityService:CreateComponent(entity, "VegetationLifecycleComponent") -- create new component that will trigger re-growth on next update

            if self.effect_blueprint ~= "" then
                EffectService:SpawnEffect( entity, self.effect_blueprint )
            end
        end
    else

        QueueEvent("OperateActionMapperRequest", entity, "FloraFertilizerToolRequest", false )
    end
end

return fertilizer_flora_tool
