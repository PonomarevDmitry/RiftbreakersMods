local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'eraser_resources_tool' ( tool )

function eraser_resources_tool:__init()
    tool.__init(self,self)
end

function eraser_resources_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_eraser_resources_tool", self.entity)

    self.validVolumeResources = { "geothermal_vent", "flammable_gas_vent", "acid_vent", "magma_vent", "supercoolant_vent", "morphium_vent" }
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

    local selectedItems = {}

    local selectorPosition = selectorComponent.position

    local entitiesResources = self:GetEntitiesResources( selectorPosition )
    ConcatUnique( selectedItems, entitiesResources )

    local entitiesResourceVolumes = self:GetEntitiesResourceVolumes( selectorPosition )
    ConcatUnique( selectedItems, entitiesResourceVolumes )

    return selectedItems
end

function eraser_resources_tool:GetEntitiesResources( selectorPosition )

    local possibleSelectedEnts = {}

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(selectorPosition, scaleVector)
    local max = VectorAdd(selectorPosition, scaleVector)

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

function eraser_resources_tool:GetEntitiesResourceVolumes( selectorPosition )

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(selectorPosition, scaleVector)
    local max = VectorAdd(selectorPosition, scaleVector)



    local resourceVolumeEntities = {}

    local predicate = {

        signature="ResourceVolumeComponent"
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    for entity in Iter( tempCollection ) do

        if ( entity == nil ) then
            goto continue
        end

        if ( IndexOf( resourceVolumeEntities, entity ) ~= nil ) then
            goto continue
        end

        local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
        if ( resourceVolumeComponent == nil ) then
            goto continue
        end

        local resourceId = ""

        local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )
        if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then
            resourceId = resourceVolumeComponentRef.type.resource.id or ""
        end

        if ( IndexOf( self.validVolumeResources, resourceId ) == nil ) then
            goto continue
        end

        Insert( resourceVolumeEntities, entity )

        ::continue::
    end

    local sorter = function( lhs, rhs )
        local position1 = EntityService:GetPosition( lhs )
        local position2 = EntityService:GetPosition( rhs )
        local distance1 = Distance( selectorPosition, position1 )
        local distance2 = Distance( selectorPosition, position2 )
        return distance1 < distance2
    end

    table.sort(resourceVolumeEntities, sorter)

    return resourceVolumeEntities
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

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    if ( is_server and is_client ) then

        if ( EntityService:HasComponent( entity, "ResourceVolumeComponent" ) ) then

            local childrenList = EntityService:GetChildren( entity, false )

            for childResource in Iter( childrenList ) do

                self:RemoveGameplayResourceComponents(childResource)

                EntityService:RemoveEntity(childResource)
            end
        end

        self:RemoveGameplayResourceComponents(entity)

        QueueEvent( "DissolveEntityRequest", entity, 0.5, 0 )

    else

        QueueEvent("OperateActionMapperRequest", entity, "ResourcesEraserToolRequest", false )
    end
end

function eraser_resources_tool:RemoveGameplayResourceComponents(entity)

    local cellIndexes = FindService:GetEntityCellIndexes(entity)

    for cellId in Iter( cellIndexes ) do

        if ( not EntityService:HasComponent( cellId, "GameplayResourceLayerComponent" ) ) then
            goto labelContinue
        end

        local gameplayResourceLayerComponentRef = reflection_helper( EntityService:GetComponent( cellId, "GameplayResourceLayerComponent" ) )

        if ( gameplayResourceLayerComponentRef.ent == nil ) then
            goto labelContinue
        end

        local linkedResourceId = gameplayResourceLayerComponentRef.ent

        if ( linkedResourceId.id ) then

            linkedResourceId = linkedResourceId.id
        end

        if ( linkedResourceId == nil ) then
            goto labelContinue
        end

        if ( linkedResourceId ~= entity ) then
            goto labelContinue
        end

        EntityService:RemoveComponent( cellId, "GameplayResourceLayerComponent" )

        if ( not EntityService:HasComponent( cellId, "GridFlagLayerComponent" ) ) then
            goto labelContinue
        end

        local gridFlagLayerComponentRef = reflection_helper( EntityService:GetComponent( cellId, "GridFlagLayerComponent" ) )

        if ( gridFlagLayerComponentRef.mask ~= 0 ) then

            gridFlagLayerComponentRef.mask = 0
        end

        ::labelContinue::
    end
end

return eraser_resources_tool