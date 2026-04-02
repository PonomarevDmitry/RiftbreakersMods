local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'spawner_respawn_tool' ( tool )

function spawner_respawn_tool:__init()
    tool.__init(self,self)
end

function spawner_respawn_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_spawner_respawn_tool", self.entity)

    local meshList = {
        "meshes/props/special/loot_containers/loot_container_jungle_root.mesh",

        "meshes/props/special/loot_containers/loot_container_acid_root.mesh",
        "meshes/props/special/loot_containers/loot_container_desert_root.mesh",
        "meshes/props/special/loot_containers/loot_container_caverns_root.mesh",
        "meshes/props/special/loot_containers/loot_container_ice_big_root.mesh",

        "meshes/props/special/loot_containers/loot_container_magma_root.mesh",
        "meshes/props/special/loot_containers/loot_container_metallic_root.mesh",
        "meshes/props/special/loot_containers/loot_container_swamp_root.mesh",
    }

    self.meshHash = {}

    for _,name in ipairs(meshList) do
        self.meshHash[name] = true
    end

    self.materialHash = {

        ["props/special/loot_container_jungle"] = "spawners/jungle_spawner_standard",
        ["props/special/loot_container_jungle_advanced"] = "spawners/jungled_spawner_advanced",
        ["props/special/loot_container_jungle_superior"] = "spawners/jungled_spawner_superior",
        ["props/special/loot_container_jungle_extreme"] = "spawners/jungle_spawner_extreme",

        ["props/special/loot_container_acid"] = "spawners/acid_spawner_standard",
        ["props/special/loot_container_acid_advanced"] = "spawners/acid_spawner_advanced",
        ["props/special/loot_container_acid_superior"] = "spawners/acid_spawner_superior",
        ["props/special/loot_container_acid_extreme"] = "spawners/acid_spawner_extreme",

        ["props/special/loot_container_desert"] = "spawners/desert_spawner_standard",
        ["props/special/loot_container_desert_advanced"] = "spawners/desert_spawner_advanced",
        ["props/special/loot_container_desert_superior"] = "spawners/desert_spawner_superior",
        ["props/special/loot_container_desert_extreme"] = "spawners/desert_spawner_extreme",

        ["props/special/loot_container_caverns_standard"] = "spawners/caverns_spawner_standard",
        ["props/special/loot_container_caverns_advanced"] = "spawners/caverns_spawner_advanced",
        ["props/special/loot_container_caverns_superior"] = "spawners/caverns_spawner_superior",
        ["props/special/loot_container_caverns_extreme"] = "spawners/caverns_spawner_extreme",

        ["props/special/loot_containers/loot_container_ice"] = "spawners/ice_spawner_standard",
        ["props/special/loot_containers/loot_container_ice_advanced"] = "spawners/ice_spawner_advanced",
        ["props/special/loot_containers/loot_container_ice_superior"] = "spawners/ice_spawner_superior",
        ["props/special/loot_containers/loot_container_ice_extreme"] = "spawners/ice_spawner_extreme",

        ["props/special/loot_container_magma"] = "spawners/magma_spawner_standard",
        ["props/special/loot_container_magma_advanced"] = "spawners/magma_spawner_advanced",
        ["props/special/loot_container_magma_superior"] = "spawners/magma_spawner_superior",
        ["props/special/loot_container_magma_extreme"] = "spawners/magma_spawner_extreme",

        ["props/special/loot_container_metallic_standard"] = "spawners/metallic_spawner_standard",
        ["props/special/loot_container_metallic_advanced"] = "spawners/metallic_spawner_advanced",
        ["props/special/loot_container_metallic_superior"] = "spawners/metallic_spawner_superior",
        ["props/special/loot_container_metallic_extreme"] = "spawners/metallic_spawner_extreme",

        ["props/special/loot_container_swamp_standard"] = "spawners/metallic_swamp_standard",
        ["props/special/loot_container_swamp_advanced"] = "spawners/metallic_swamp_advanced",
        ["props/special/loot_container_swamp_superior"] = "spawners/metallic_swamp_superior",
        ["props/special/loot_container_swamp_extreme"] = "spawners/metallic_swamp_extreme",
    }
end

function spawner_respawn_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function spawner_respawn_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function spawner_respawn_tool:FindEntitiesToSelect( selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local predicate = {
        signature="MeshComponent",
        filter = function(entity)
            
            local meshComponent = EntityService:GetComponent( entity, "MeshComponent" )
            if( meshComponent == nil ) then
                return false
            end

            local meshComponentRef = reflection_helper( meshComponent )

            local meshName = tostring( meshComponentRef.mesh )
            local materialName = tostring( meshComponentRef.material )

            if ( self.meshHash[meshName] == nil ) then
                return false
            end

            if ( self.materialHash[materialName] == nil ) then
                return false
            end

            return true
        end
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

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
            goto labelContinue
        end

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function spawner_respawn_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function spawner_respawn_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function spawner_respawn_tool:OnRotate()
end

function spawner_respawn_tool:OnActivateSelectorRequest()

    self.activated = true
    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function spawner_respawn_tool:OnActivateEntity( entity )

    if ( not EntityService:IsAlive( entity ) ) then
        return
    end

    local meshComponent = EntityService:GetComponent( entity, "MeshComponent" )
    if( meshComponent == nil ) then
        return
    end

    local meshComponentRef = reflection_helper( meshComponent )

    local meshName = tostring( meshComponentRef.mesh )
    local materialName = tostring( meshComponentRef.material )

    if ( self.meshHash[meshName] == nil ) then
        return
    end

    if ( self.materialHash[materialName] == nil ) then
        return
    end

    local newBlueprint = self.materialHash[materialName]

    local mapperName = "RespawnBioAnomaliesToolsSingleRequest|" .. newBlueprint

    QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
end

return spawner_respawn_tool
