local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'vents_preserve_tool' ( tool )

function vents_preserve_tool:__init()
    tool.__init(self,self)
end

function vents_preserve_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_vents_preserve_tool", self.entity)

    self.validVolumeResources = { "geothermal_vent", "flammable_gas_vent", "acid_vent", "magma_vent", "supercoolant_vent", "morphium_vent" }
end

function vents_preserve_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function vents_preserve_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function vents_preserve_tool:FindEntitiesToSelect( selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)



    local predicate = {

        signature="ResourceVolumeComponent"
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

        local resourceVolumeComponent = EntityService:GetComponent( entity, "ResourceVolumeComponent" )
        if ( resourceVolumeComponent == nil ) then
            goto labelContinue
        end

        local resourceId = ""

        local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )
        if ( resourceVolumeComponentRef.type ~= nil and resourceVolumeComponentRef.type.resource ~= nil and resourceVolumeComponentRef.type.resource.id ~= nil ) then
            resourceId = resourceVolumeComponentRef.type.resource.id or ""
        end

        if ( resourceId == "" or resourceId == nil ) then
            goto labelContinue
        end

        if ( IndexOf( self.validVolumeResources, resourceId ) == nil ) then
            goto labelContinue
        end

        local databaseEntity = EntityService:GetOrCreateDatabase( entity )
        if ( databaseEntity ~= nil ) then
            
            if ( databaseEntity:HasInt("$VentStore_Destroy") ) then

                goto labelContinue
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function vents_preserve_tool:AddedToSelection( entity )

    QueueEvent( "SelectEntityRequest", entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function vents_preserve_tool:RemovedFromSelection( entity )

    QueueEvent( "DeselectEntityRequest", entity )

    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function vents_preserve_tool:OnRotate()
end

function vents_preserve_tool:OnActivateSelectorRequest()

    self.activated = true

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function vents_preserve_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local mapperName = "VentStoreRequest|" .. tostring(self.playerId)

    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
end

return vents_preserve_tool
