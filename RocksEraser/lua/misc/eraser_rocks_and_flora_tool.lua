local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_rocks_and_flora_tool' ( tool )

function eraser_rocks_and_flora_tool:__init()
    tool.__init(self,self)
end

function eraser_rocks_and_flora_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_rocks_and_flora_tool", self.entity)

    self.poogretPlantSmall = CalcHash("props/special/interactive/poogret_plant_small_01")
    self.poogretPlantMedium = CalcHash("props/special/interactive/poogret_plant_medium_01")
    self.poogretPlantBig = CalcHash("props/special/interactive/poogret_plant_big_01")

    self.previousSelectedFlora = {}
    self.selectedEntitiesFlora = {}
end

function eraser_rocks_and_flora_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function eraser_rocks_and_flora_tool:FindEntitiesToSelect( selectorComponent )

    self.selectorComponent = selectorComponent

    local predicate = {

        filter = function( entity )

            local blueprintName = EntityService:GetBlueprintName( entity )
            if ( blueprintName == "" or blueprintName == nil ) then
                return false
            end
        
            local stringIndex = string.find( blueprintName, "props/rocks/" )
        
            if ( stringIndex == nil ) then
                return false
            end
        
            if ( stringIndex ~= 1 ) then
                return false
            end

            if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

                local groupId = EntityService:GetPhysicsGroupId( entity )

                if ( groupId == "destructible" ) then

                    return true
                else
                    return false
                end
            end

            return true
        end
    };

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(position, scaleVector)
    local maxVector = VectorAdd(position, scaleVector)

    local tempCollection = FindService:FindEntitiesByPredicateInBox( minVector, maxVector, predicate )

    local possibleSelectedEnts = {}

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( possibleSelectedEnts, entity ) ~= nil ) then
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

function eraser_rocks_and_flora_tool:OnUpdate()

    local selectorPosition = self.selectorComponent.position

    local boundsSize = { x=1.0, y=1000.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local minVector = VectorSub(selectorPosition, scaleVector)
    local maxVector = VectorAdd(selectorPosition, scaleVector)

    local result = {}

    self:FillFloraByTypeComponent(result, minVector, maxVector)

    self:FillFloraByVegetationLifecycleEnablerComponent(result, minVector, maxVector)

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

    local previousSelectedFlora = self.selectedEntitiesFlora

    self.selectedEntitiesFlora = result

    for entity in Iter( previousSelectedFlora ) do

        if ( IndexOf( self.selectedEntitiesFlora, entity ) == nil ) then

            self:RemovedFromSelectionFlora( entity )
        end
    end

    for entity in Iter( self.selectedEntitiesFlora ) do

        if ( IndexOf( previousSelectedFlora, entity ) == nil ) then

            self:AddedToSelectionFlora( entity )

            if ( self.activated ) then

                self:OnActivateEntityFlora( entity )
            end
        end
    end
end

function eraser_rocks_and_flora_tool:FillFloraByTypeComponent(result, minVector, maxVector)

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

function eraser_rocks_and_flora_tool:FillFloraByVegetationLifecycleEnablerComponent(result, minVector, maxVector)

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

function eraser_rocks_and_flora_tool:FillFloraByVegetationDummyRoot(result, minVector, maxVector)

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

function eraser_rocks_and_flora_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/current" )
end

function eraser_rocks_and_flora_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function eraser_rocks_and_flora_tool:AddedToSelectionFlora( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/active" )
end

function eraser_rocks_and_flora_tool:RemovedFromSelectionFlora( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function eraser_rocks_and_flora_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function eraser_rocks_and_flora_tool:OnRotate()
end

function eraser_rocks_and_flora_tool:OnActivateSelectorRequest()
    self.activated = true

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end

    for entity in Iter( self.selectedEntitiesFlora ) do
        self:OnActivateEntityFlora( entity )
    end
end

function eraser_rocks_and_flora_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        if ( EntityService:GetComponent( entity, "PhysicsComponent") ~= nil ) then

            EntityService:DisableCollisions( entity )

            BuildingService:DisablePhysics( entity )

            EntityService:RequestDestroyPattern( entity, "default" )
        end

        EntityService:DissolveEntity( entity, 0.5 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "RocksEraserRequest", false )
    end
end

function eraser_rocks_and_flora_tool:OnActivateEntityFlora( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent" )

        EntityService:RequestDestroyPattern( entity, "default" )

        QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "RocksAndFloraEraserRequest", false )
    end
end

function eraser_rocks_and_flora_tool:OnRelease()

    for entity in Iter( self.selectedEntitiesFlora ) do
        self:RemovedFromSelectionFlora( entity )
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return eraser_rocks_and_flora_tool
