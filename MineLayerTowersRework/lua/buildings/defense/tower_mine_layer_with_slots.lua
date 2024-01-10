require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_mine_layer_with_slots' ( drone_spawner_building )

function tower_mine_layer_with_slots:__init()
    drone_spawner_building.__init(self,self)
end

function tower_mine_layer_with_slots:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self.lifting_drones = 0

    self:CreateCenterPoint()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
end

function tower_mine_layer_with_slots:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateCenterPoint()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")
end

function tower_mine_layer_with_slots:OnDroneLiftingStarted()
    self.lifting_drones = self.lifting_drones + 1
    self.data:SetInt("lifting_drones", self.lifting_drones)
end

function tower_mine_layer_with_slots:OnDroneLiftingEnded()
    self.lifting_drones = self.lifting_drones - 1
    self.data:SetInt("lifting_drones", self.lifting_drones)
end

function tower_mine_layer_with_slots:SpawnDrones()

    self:CleanupDrones()

    self.lifting_drones = 0
    self.data:SetInt("lifting_drones", self.lifting_drones)

    local DRONE_FADE_TIME = 0.3

    local isActive = self.data:GetIntOrDefault( "activated", 0 ) == 1;

    local blueprints = Split( self.drone_blueprint, ",") 

    local droneIdx = 0

    local towerMinesArray = self:GetMinesArray()

    for attachment in Iter( self.drone_landing_spots ) do

        for towerMineBlueprint in Iter( towerMinesArray ) do

            for i=1,self.drone_per_attachment do

                local drone_blueprint = blueprints[ (droneIdx % #blueprints) + 1 ]

                local drone = EntityService:SpawnEntity( drone_blueprint, attachment, EntityService:GetTeam(self.entity) )

                EntityService:SetScale( drone, 0.75,0.75,0.75 )

                UnitService:SetCurrentTarget( drone, "owner", attachment )

                if self.drones_visible then
                    QueueEvent( "FadeEntityInRequest", drone, DRONE_FADE_TIME )
                else
                    QueueEvent( "FadeEntityOutRequest", drone, 1 )
                end

                self:RegisterHandler( drone, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
                self:RegisterHandler( drone, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
                self:RegisterHandler( drone, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
                self:RegisterHandler( drone, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
                self:DroneSpawned( drone )

                local database = EntityService:GetDatabase( drone )
                database:SetInt("drone_id", droneIdx )
                database:SetFloat("drone_search_radius", self.drone_search_radius )
                database:SetString("plant_blueprint", towerMineBlueprint )

                droneIdx = droneIdx + 1

                Insert( self.drones, drone )

                self:UpdateActiveDrones( drone, isActive )
            end
        end
    end
end

function tower_mine_layer_with_slots:GetMinesArray()

    local DEFAULT_MINE_BLUEPRINT = "units/drones/drone_mine_root";

    local result = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")

    if ( equipmentComponent == nil ) then
        QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "EquipmentComponent" )

        local blueprintName = EntityService:GetBlueprintName(self.entity)

        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        if ( blueprint ~= nil ) then
            equipmentComponent = blueprint:GetComponent("EquipmentComponent")
        end
    end

    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local mineBlueprint = DEFAULT_MINE_BLUEPRINT

            for i=1,slot.subslots.count do

                local entities = slot.subslots[i]

                local entity = entities[1]
                if entity and entity.id then

                    local blueprintDatabase = EntityService:GetBlueprintDatabase( entity.id )

                    if ( blueprintDatabase and blueprintDatabase:HasString("mine_blueprint") ) then

                        mineBlueprint = blueprintDatabase:GetString("mine_blueprint")
                    end
                end
            end

            Insert(result, mineBlueprint)
        end
    else
        Insert(result, DEFAULT_MINE_BLUEPRINT)
    end

    return result
end

function tower_mine_layer_with_slots:OnItemEquippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end
end

function tower_mine_layer_with_slots:OnItemUnequippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end
end

function tower_mine_layer_with_slots:OnOperateActionMenuEvent()

    local blueprintArray = {
        "items/tower_mines/drone_mine_root",

        "items/tower_mines/drone_mine_root_acid",
        "items/tower_mines/drone_mine_root_cryogenic",
        "items/tower_mines/drone_mine_root_energy",
        "items/tower_mines/drone_mine_root_incendiary",
        
        "items/tower_mines/drone_mine_root_holo_decoy",
        "items/tower_mines/drone_mine_root_gravity",
        "items/tower_mines/drone_mine_root_nuclear",
        "items/tower_mines/drone_mine_root_sonic"
    }

    for blueprintName in Iter( blueprintArray ) do

        local item = ItemService:GetFirstItemForBlueprint( self.entity, blueprintName )

        if item == INVALID_ID then
            ItemService:AddItemToInventory( self.entity, blueprintName )
        end
    end

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    local player = PlayerService:GetPlayerControlledEnt( owner )

    for blueprintName in Iter( blueprintArray ) do

        local item = ItemService:GetFirstItemForBlueprint( player, blueprintName )

        if item == INVALID_ID then
            ItemService:AddItemToInventory( player, blueprintName )
        end
    end
end

-- #region Drone Point

function tower_mine_layer_with_slots:CreateCenterPoint()

    local pointEntityBlueprintName = "misc/area_center_point"

    if ( self.pointEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == pointEntityBlueprintName ) then

                self.pointEntity = child
                ItemService:SetInvisible(self.pointEntity, true)

                goto continue
            end
        end

        ::continue::
    end

    if ( self.pointEntity == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = self.data:GetFloatOrDefault("center_point_entity_x", transform.position.x)
        local newPositionZ = self.data:GetFloatOrDefault("center_point_entity_z", transform.position.z)

        local team = EntityService:GetTeam( self.entity )
        self.pointEntity = EntityService:SpawnAndAttachEntity( pointEntityBlueprintName, self.entity, team )

        ItemService:SetInvisible(self.pointEntity, true)

        self:SetCenterPointPosition( newPositionX, newPositionZ )
    end

    if ( self.pointEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == pointEntityBlueprintName and child ~= self.pointEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    EntityService:SetName( self.pointEntity, "center_point_entity" )

    self.data:SetInt("center_point_entity", self.pointEntity)
end

function tower_mine_layer_with_slots:OnDronePointEvent(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName == "AreaCenterPointChangeEvent" ) then
        local newPositionX = eventDatabase:GetFloat("point_x")
        local newPositionZ = eventDatabase:GetFloat("point_z")

        self:SetCenterPointPosition( newPositionX, newPositionZ )

    elseif ( eventName == "AreaCenterPointSelectedEvent" ) then

        local selected = ( eventDatabase:GetStringOrDefault("isBuildingSelected", "0") == "1" )

        self.dronePointSelected = selected

        self:UpdateDronePointSkinMaterial()
    end
end

function tower_mine_layer_with_slots:OnActivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = true

    self:UpdateDronePointSkinMaterial()
end

function tower_mine_layer_with_slots:OnDeactivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = false

    self:UpdateDronePointSkinMaterial()
end

function tower_mine_layer_with_slots:SetCenterPointPosition( newPositionX, newPositionZ )

    self.data:SetFloat("center_point_entity_x", newPositionX)
    self.data:SetFloat("center_point_entity_z", newPositionZ)

    local transform = EntityService:GetWorldTransform( self.entity )

    local newRelativePosition ={
        x = newPositionX - transform.position.x,
        y = 0,
        z = newPositionZ - transform.position.z
    }

    local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

    local pointX = SnapValue(inverteRotatedPosition.x, 1)
    local pointZ = SnapValue(inverteRotatedPosition.z, 1)

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

    self:RepositionLinkEntity()
end

function tower_mine_layer_with_slots:UpdateDisplayRadiusVisibility( show, entity )

    self.display_radius_requesters = self.display_radius_requesters or {}

    if show then
        if self.display_radius_requesters[ entity ] then
            return
        end

        self.display_radius_requesters[ entity ] = true

        local count = 0
        for entityTemp,_ in pairs(self.display_radius_requesters) do
            if ( EntityService:IsAlive( entityTemp ) ) then
                count = count + 1
            end
        end

        if count == 1 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" );

            local component = reflection_helper( EntityService:CreateComponent(self.pointEntity,"DisplayRadiusComponent") )
            component.min_radius = self.display_radius_size.min;
            component.max_radius = self.display_radius_size.max;
            component.max_radius_blueprint = self.display_effect_blueprint;

            self.dronePointSelected = self.dronePointSelected or false

            if ( self.dronePointSelected ) then
                EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
            else
                EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
            end

            self:CreateLinkEntity()

            self:RepositionLinkEntity()
        end
    else
        self.display_radius_requesters[ entity ] = nil

        local count = 0

        for entityTemp,_ in pairs(self.display_radius_requesters) do
            if ( EntityService:IsAlive( entityTemp ) ) then
                count = count + 1
            end
        end
        
        if count == 0 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )
            EntityService:RemoveMaterial( self.pointEntity, "selected" )

            self:RemoveLinkEntity()
        end
    end
end

function tower_mine_layer_with_slots:UpdateDronePointSkinMaterial()

    local count = 0
    for entityTemp,_ in pairs(self.display_radius_requesters) do
        if ( EntityService:IsAlive( entityTemp ) ) then
            count = count + 1
        end
    end

    self.dronePointSelected = self.dronePointSelected or false

    if count > 0 then
        if ( self.dronePointSelected ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
        end
    else
        EntityService:RemoveMaterial( self.pointEntity, "selected" )
    end
end

function tower_mine_layer_with_slots:CreateLinkEntity()

    local linkEntityBlueprintName = "effects/area_center_point_effects/area_center_point_link"

    if ( self.linkEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName ) then

                self.linkEntity = child
                ItemService:SetInvisible(self.linkEntity, true)

                goto continue
            end
        end

        ::continue::
    end

    if ( self.linkEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.linkEntity = EntityService:SpawnAndAttachEntity( linkEntityBlueprintName, self.entity, team)
        ItemService:SetInvisible(self.linkEntity, true)
    end

    if ( self.linkEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName and child ~= self.linkEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end
end

function tower_mine_layer_with_slots:RemoveLinkEntity()

    if ( self.linkEntity == nil ) then
        return
    end

    EntityService:RemoveEntity(self.linkEntity)
    self.linkEntity = nil
end

function tower_mine_layer_with_slots:RepositionLinkEntity()

    if ( self.linkEntity == nil or self.pointEntity == nil ) then
        return
    end

    local selfPosition = EntityService:GetPosition(self.entity)
    local pointPosition = EntityService:GetPosition(self.pointEntity)

    local direction = VectorMulByNumber( Normalize( VectorSub( pointPosition, selfPosition ) ), 2.0 )
    selfPosition = VectorAdd(selfPosition, direction)

    local lightningComponent = reflection_helper(EntityService:GetComponent(self.linkEntity, "LightningComponent"))

    local container = rawget(lightningComponent.lighning_vec, "__ptr");

    local item = container:GetItem(0)
    if ( item == nil ) then 
        item = container:CreateItem()
    end

    local instance =  reflection_helper(item)

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    local sizePoint = EntityService:GetBoundsSize( self.pointEntity )

    instance.start_point.x = selfPosition.x
    instance.start_point.y = selfPosition.y + sizeSelf.y
    instance.start_point.z = selfPosition.z

    instance.end_point.x = pointPosition.x
    instance.end_point.y = pointPosition.y + sizePoint.y + 2
    instance.end_point.z = pointPosition.z
end

function tower_mine_layer_with_slots:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == true) then

        self:GettingInfoFromBaseToUpgrade(eventEntity)
    else
        self:GettingInfoFromRuin()
    end
end

function tower_mine_layer_with_slots:GettingInfoFromBaseToUpgrade(eventEntity)

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindGridOwnersByBox( min, max )

    for entity in Iter( entities ) do

        if ( entity == eventEntity ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper(buildingDesc)
        if ( buildingDescRef.upgrade ~= selfBlueprintName ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= selfLowName ) then
            goto continue
        end

        local baseDatabase = EntityService:GetDatabase( entity )

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = baseDatabase:GetFloatOrDefault("center_point_entity_x", transform.position.x)
        local newPositionZ = baseDatabase:GetFloatOrDefault("center_point_entity_z", transform.position.z)

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function tower_mine_layer_with_slots:GettingInfoFromRuin()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for ruinEntity in Iter( entities ) do

        local blueprintName = EntityService:GetBlueprintName(ruinEntity)
        if ( blueprintName ~= selfRuinsBlueprint ) then
            goto continue
        end

        local ruinPosition = EntityService:GetPosition(ruinEntity)
        if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
            goto continue
        end

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = ruinDatabase:GetFloatOrDefault("center_point_entity_x", transform.position.x)
        local newPositionZ = ruinDatabase:GetFloatOrDefault("center_point_entity_z", transform.position.z)

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function tower_mine_layer_with_slots:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetWasSold() == true) then
        return
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for ruinEntity in Iter( entities ) do

        local blueprintName = EntityService:GetBlueprintName(ruinEntity)
        if ( blueprintName ~= selfRuinsBlueprint ) then
            goto continue
        end

        local ruinPosition = EntityService:GetPosition(ruinEntity)
        if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
            goto continue
        end

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local pointPosition = EntityService:GetPosition(self.pointEntity)

        ruinDatabase:SetFloat("center_point_entity_x", pointPosition.x)
        ruinDatabase:SetFloat("center_point_entity_z", pointPosition.z)

        ::continue::
    end
end

-- #endregion Drone Point

return tower_mine_layer_with_slots
