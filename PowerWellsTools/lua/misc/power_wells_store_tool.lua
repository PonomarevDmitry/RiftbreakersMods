local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'power_wells_destroy_tool' ( tool )

function power_wells_destroy_tool:__init()
    tool.__init(self,self)
end

function power_wells_destroy_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_power_wells_destroy_tool", self.entity)
end

function power_wells_destroy_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function power_wells_destroy_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function power_wells_destroy_tool:FindEntitiesToSelect( selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)



    local predicate = {

        signature="SelectableComponent,InteractiveComponent,GridCullerComponent"
    };

    local searchEntities = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    local result = {}

    for entity in Iter( searchEntities ) do

        if ( entity == nil or entity == INVALID_ID ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local stringNumber = string.find( blueprintName, "props/special/power_wells/power_well_source_" )
        if ( stringNumber ~= 1 ) then

            goto labelContinue
        end

        local interactiveComponent = EntityService:GetConstComponent( entity, "InteractiveComponent" )
        if ( interactiveComponent == nil ) then
            goto labelContinue
        end

        local interactiveComponentRef = reflection_helper( interactiveComponent )
        if ( interactiveComponentRef.slot ~= "ACTIVATOR" ) then
            goto labelContinue
        end

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity ~= nil ) then
            
            if ( not databaseEntity:HasString("blueprint") ) then

                goto labelContinue
            end

            if ( databaseEntity:HasInt("$PowerWellStore_Destroy") ) then

                goto labelContinue
            end

            local blueprintName = databaseEntity:GetString("blueprint")

            local stringNumber = string.find( blueprintName, "props/special/power_wells/power_well_" )
            if ( stringNumber ~= 1 ) then

                goto labelContinue
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function power_wells_destroy_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function power_wells_destroy_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function power_wells_destroy_tool:OnRotate()
end

function power_wells_destroy_tool:OnActivateSelectorRequest()

    self.activated = true

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function power_wells_destroy_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local mapperName = "PowerWellStoreRequest|" .. tostring(self.playerId)

    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
end

return power_wells_destroy_tool
