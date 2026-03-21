local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'spawner_respawn_all_map_tool' ( tool )

function spawner_respawn_all_map_tool:__init()
    tool.__init(self,self)
end

function spawner_respawn_all_map_tool:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_spawner_respawn_all_map_tool", self.entity)

    self.scaleMap = {
        1,
    }

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

        ["props/special/loot_container_ice_standard"] = "spawners/ice_spawner_standard",
        ["props/special/loot_container_ice_advanced"] = "spawners/ice_spawner_advanced",
        ["props/special/loot_container_ice_superior"] = "spawners/ice_spawner_superior",
        ["props/special/loot_container_ice_extreme"] = "spawners/ice_spawner_extreme",

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

    self.allSpawners = {}

    local world_min = MissionService:GetWorldBoundsMin();
    local world_max = MissionService:GetWorldBoundsMax();

    world_min.y = -100.0
    world_max.y = 100.0

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
    
    local entities = FindService:FindEntitiesByPredicateInBox( world_min, world_max, predicate )

    for entity in Iter( entities ) do

        if ( entity == nil or entity == INVALID_ID ) then
            goto labelContinue
        end

        if ( not EntityService:IsAlive( entity ) ) then
            goto labelContinue
        end

        if ( IndexOf( self.allSpawners, entity ) ~= nil ) then
            goto labelContinue
        end

        local idComponentName = EntityService:GetName( entity )

        -- Ignore Into Dark Anomaly to do not create a soft lock. 
        if ( idComponentName == "dlc_2_anomaly" or idComponentName == "swamp_harvest_anomaly" ) then
            goto labelContinue
        end

        Insert( self.allSpawners, entity )

        ::labelContinue::
    end

    self.popupShown = false
    self.timeoutTime = nil
end

function spawner_respawn_all_map_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function spawner_respawn_all_map_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function spawner_respawn_all_map_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function spawner_respawn_all_map_tool:FindEntitiesToSelect( selectorComponent )

    return self.allSpawners
end

function spawner_respawn_all_map_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        self:AddedToSelection( entity )
    end
end

function spawner_respawn_all_map_tool:AddedToSelection( entity )

    EntityService:SetMaterial( entity, "hologram/current", "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, "hologram/current", "selected" )
        end
    end
end

function spawner_respawn_all_map_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:RemoveMaterial( child, "selected" )
        end
    end
end

function spawner_respawn_all_map_tool:OnRotate()
end

function spawner_respawn_all_map_tool:OnActivateSelectorRequest()

    if ( #self.allSpawners == 0 ) then
        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    if( self.popupShown == false ) then

        self.popupShown = true

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/spawner_activate_tools/respawn_all_spawners")

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")
    end
end

function spawner_respawn_all_map_tool:OnActivateEntity()
end

function spawner_respawn_all_map_tool:OnGuiPopupResultEvent( evt )

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown

    self:UnregisterHandler(evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent")

    if ( evt:GetResult() == "button_yes" ) then

        for entity in Iter( self.allSpawners ) do

            self:RespawnEntity( entity )
        end
    end

    self.popupShown = false
end

function spawner_respawn_all_map_tool:RespawnEntity( entity )

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

return spawner_respawn_all_map_tool
