local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_flora_tool' ( tool )

function eraser_flora_tool:__init()
    tool.__init(self,self)
end

function eraser_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_flora_tool", self.entity)

    self.poogretPlantSmall = CalcHash("props/special/interactive/poogret_plant_small_01")
    self.poogretPlantMedium = CalcHash("props/special/interactive/poogret_plant_medium_01")
    self.poogretPlantBig = CalcHash("props/special/interactive/poogret_plant_big_01")
end

function eraser_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_flora_tool:FindEntitiesToSelect( selectorComponent )

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

function eraser_flora_tool:FillFloraByTypeComponent(result, minVector, maxVector)

    self.predicateType = self.predicateType or {

        signature = "TypeComponent",

        filter = function(entity)

            local blueprintName = EntityService:GetBlueprintName(entity)

            if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
                return false
            end

            if ( EntityService:CompareType( entity, "flora" ) ) then
                return true
            end

            if ( mod_flora_eraser_enable_creeper and mod_flora_eraser_enable_creeper == 1 ) then

                if ( string.find(blueprintName, "units/ground/cosmic_crystal_creeper_branch" ) ~= nil ) then

                    return true
                end

                if ( string.find(blueprintName, "units/ground/crystal_creeper_branch" ) ~= nil ) then

                    return true
                end

                if ( string.find(blueprintName, "units/ground/creeper_branch" ) ~= nil ) then

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

function eraser_flora_tool:FillFloraByVegetationLifecycleEnablerComponent(result, minVector, maxVector)

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

        local blueprintName = EntityService:GetBlueprintName(entity)
        if ( string.find(blueprintName, "props/special/interactive/poogret_plant" ) ~= nil ) then
            goto labelContinue
        end

        local enablerComponent = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( enablerComponent == nil ) then
            goto labelContinue
        end

        local enablerComponentRef = reflection_helper(enablerComponent)
        if ( enablerComponentRef.chain_destination and enablerComponentRef.chain_destination.hash ) then

            local nextPlantHash = enablerComponentRef.chain_destination.hash

            if ( nextPlantHash == self.poogretPlantSmall or nextPlantHash == self.poogretPlantMedium or nextPlantHash == self.poogretPlantBig ) then

                goto labelContinue
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end
end

function eraser_flora_tool:FillFloraByVegetationDummyRoot(result, minVector, maxVector)

    local entities = FindService:FindEntitiesByBlueprintInBox( "props/base/vegetation_dummy_root", minVector, maxVector )

    for entity in Iter( entities ) do

        if ( entity == nil ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        local enablerComponent = EntityService:GetComponent( entity, "VegetationLifecycleEnablerComponent")
        if ( enablerComponent ~= nil ) then

            local enablerComponentRef = reflection_helper(enablerComponent)
            if ( enablerComponentRef.chain_destination and enablerComponentRef.chain_destination.hash ) then

                local nextPlantHash = enablerComponentRef.chain_destination.hash

                if ( nextPlantHash == self.poogretPlantSmall or nextPlantHash == self.poogretPlantMedium or nextPlantHash == self.poogretPlantBig ) then

                    goto labelContinue
                end
            end
        end

        Insert(result, entity)

        ::labelContinue::
    end
end

function eraser_flora_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function eraser_flora_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function eraser_flora_tool:OnRotate()
end

function eraser_flora_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

        EntityService:RequestDestroyPattern( entity, "default" )

        QueueEvent( "DissolveEntityRequest", entity, 2.0, 0 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "FloraEraserToolRequest", false )
    end
end

return eraser_flora_tool
