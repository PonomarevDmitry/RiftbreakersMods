require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_drone_attack_with_slots' ( drone_spawner_building )

local DEFAULT_TOWER_ATTACK_DRONE_BLUEPRINT = "items/tower_attack_drones/drone_attack_acid";

function tower_drone_attack_with_slots:__init()
    drone_spawner_building.__init(self,self)
end

function tower_drone_attack_with_slots:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self:CreateCenterPoint()
    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    local playerId = PlayerService:GetPlayerForEntity( self.entity )

    if ( PlayerService:IsInFighterMode( playerId ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self.data:SetString("action_icon", "gui/menu/research/icons/towers_drone_attack" )

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateCenterPoint()
    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self.showMenu = self.showMenu or 0

    self.data:SetString("action_icon", "gui/menu/research/icons/towers_drone_attack" )

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipedItemEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipItemRequest", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "TimerElapsedEvent", "OnTimerElapsedEvent")

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function tower_drone_attack_with_slots:SpawnDrones()

    self:CleanupDrones();

    local DRONE_FADE_TIME = 0.3

    local isActive = self.data:GetIntOrDefault( "activated", 0 ) == 1;

    local blueprints = self:GetDronesTemplatesArray()

    local droneIdx = 0;

    for attachmentNumber=1,#self.drone_landing_spots do

        local attachment = self.drone_landing_spots[attachmentNumber]

        local drone_blueprint = blueprints[ ( (attachmentNumber-1) % #blueprints ) + 1 ]

        for i=1,self.drone_per_attachment do

            local drone = EntityService:SpawnEntity( drone_blueprint, attachment, EntityService:GetTeam(self.entity) )
            EntityService:SetScale( drone, 0.75,0.75,0.75 )

            UnitService:SetCurrentTarget( drone, "owner", attachment )
            if self.drones_visible then
                --QueueEvent( "FadeEntityInRequest", drone, DRONE_FADE_TIME )
                EntityService:FadeEntity( drone, DD_FADE_IN, DRONE_FADE_TIME )
            else
                --QueueEvent( "FadeEntityOutRequest", drone, 1 )
                EntityService:FadeEntity( drone, DD_FADE_OUT, 1 )
            end

            self:RegisterHandler( drone, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
            self:RegisterHandler( drone, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
            self:RegisterHandler( drone, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
            self:RegisterHandler( drone, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
            self:DroneSpawned( drone )

            local database = EntityService:GetOrCreateDatabase( drone )
            database:SetInt("drone_id", droneIdx )
            database:SetFloat("drone_search_radius", self.drone_search_radius )
            droneIdx = droneIdx + 1
            Insert( self.drones, drone )

            self:UpdateActiveDrones( drone, isActive )
        end
    end
end

function tower_drone_attack_with_slots:GetDronesTemplatesArray()

    local DEFAULT_DRONE_BLUEPRINT = "units/drones/drone_attack";

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

            local droneBlueprint = DEFAULT_DRONE_BLUEPRINT

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                local blueprintDatabase = EntityService:GetBlueprintDatabase( modItem ) or EntityService:GetOrCreateDatabase( modItem )

                if ( blueprintDatabase and blueprintDatabase:HasString("drone_blueprint") ) then

                    droneBlueprint = blueprintDatabase:GetString("drone_blueprint")
                end
            end

            Insert(result, droneBlueprint)
        end
    else
        Insert(result, DEFAULT_DRONE_BLUEPRINT)
    end

    return result
end

function tower_drone_attack_with_slots:OnItemEquippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end

    local slotName = evt:GetSlot()
    local item = evt:GetItem()

    local itemBlueprintName = ""

    if ( item ~= nil and item ~= INVALID_ID ) then
        itemBlueprintName = EntityService:GetBlueprintName(item)
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetOrCreateDatabase( self.entity )
    database:SetString(key, itemBlueprintName)

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:OnItemUnequippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end

    local slotName = evt:GetSlot()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetOrCreateDatabase( self.entity )
    database:SetString(key, "")

    self:PopulateSpecialActionInfo()

    EntityService:CreateComponent( self.entity, "TimerComponent")

    QueueEvent( "SetTimerRequest", self.entity, "RefreshIcons", 3 )
end

function tower_drone_attack_with_slots:OnTimerElapsedEvent( evt )

    self:PopulateSpecialActionInfo()
end

-- #region Drone Point

function tower_drone_attack_with_slots:CreateCenterPoint()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local pointEntityBlueprintName = "misc/area_center_point"

    if ( self.pointEntity ~= nil and not EntityService:IsAlive(self.pointEntity) ) then
        self.pointEntity = nil
    end

    if ( self.pointEntity ~= nil ) then

        local pointEntityParent = EntityService:GetParent( self.pointEntity )

        if ( pointEntityParent == nil or pointEntityParent == INVALID_ID or pointEntityParent ~= self.entity ) then
            self.pointEntity = nil
        end
    end

    if ( self.pointEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == pointEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.pointEntity = child
                ItemService:SetInvisible(self.pointEntity, true)

                break
            end
        end
    end

    if ( self.pointEntity == nil ) then

        local newPositionX = 0
        local newPositionZ = 0

        if ( self.data:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = self.data:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

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

function tower_drone_attack_with_slots:OnDronePointEvent(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName == "AreaCenterPointChangeEvent" ) then

        local selfPosition = EntityService:GetPosition( self.entity )

        local newPositionX = eventDatabase:GetFloat("point_x") - selfPosition.x
        local newPositionZ = eventDatabase:GetFloat("point_z") - selfPosition.z

        self:SetCenterPointPosition( newPositionX, newPositionZ )

    elseif ( eventName == "AreaCenterPointSelectedEvent" ) then

        local selected = ( eventDatabase:GetStringOrDefault("isBuildingSelected", "0") == "1" )

        self.dronePointSelected = selected

        self:UpdateDronePointSkinMaterial()
    end
end

function tower_drone_attack_with_slots:OnActivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = true

    self:UpdateDronePointSkinMaterial()
end

function tower_drone_attack_with_slots:OnDeactivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = false

    self:UpdateDronePointSkinMaterial()
end

function tower_drone_attack_with_slots:SetCenterPointPosition( newPositionX, newPositionZ )

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local newRelativePosition ={
        x = newPositionX,
        y = 0,
        z = newPositionZ
    }

    self.data:SetVector(selfLowName .. "_center_point_vector", newRelativePosition)

    local transform = EntityService:GetWorldTransform( self.entity )

    local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

    local pointX = SnapValue(inverteRotatedPosition.x, 1)
    local pointZ = SnapValue(inverteRotatedPosition.z, 1)

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

    self:RepositionLinkEntity()
end

function tower_drone_attack_with_slots:UpdateDisplayRadiusVisibility( show, entity )

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
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )

            local displayRadiusComponent = EntityService:CreateComponent(self.pointEntity, "DisplayRadiusComponent")
            if ( displayRadiusComponent ~= nil ) then

                local displayRadiusComponentRef = reflection_helper( displayRadiusComponent )
                displayRadiusComponentRef.min_radius = self.display_radius_size.min
                displayRadiusComponentRef.max_radius = self.display_radius_size.max
                displayRadiusComponentRef.max_radius_blueprint = self.display_effect_blueprint
            end

            self:SetPointEntitySelectedSkin()

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

function tower_drone_attack_with_slots:SetPointEntitySelectedSkin()

    self.dronePointSelected = self.dronePointSelected or false

    if ( self.dronePointSelected ) then

        EntityService:SetMaterial( self.pointEntity, "hologram/pass", "selected" )
        
    else

        EntityService:SetMaterial( self.pointEntity, "hologram/blue", "selected" )
    end
end

function tower_drone_attack_with_slots:UpdateDronePointSkinMaterial()

    local count = 0
    for entityTemp,_ in pairs(self.display_radius_requesters) do
        if ( EntityService:IsAlive( entityTemp ) ) then
            count = count + 1
        end
    end

    self.dronePointSelected = self.dronePointSelected or false

    if count > 0 then
        self:SetPointEntitySelectedSkin()
    else
        EntityService:RemoveMaterial( self.pointEntity, "selected" )
    end

    self:RepositionLinkEntity()
end

function tower_drone_attack_with_slots:CreateLinkEntity()

    local linkEntityBlueprintName = "effects/area_center_point_effects/area_center_point_link"

    if ( self.linkEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.linkEntity = child
                ItemService:SetInvisible(self.linkEntity, true)

                break
            end
        end
    end

    if ( self.linkEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.linkEntity = EntityService:SpawnAndAttachEntity( linkEntityBlueprintName, self.entity, team)

        EntityService:CreateComponent(self.linkEntity, "EffectReferenceComponent")

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

function tower_drone_attack_with_slots:RemoveLinkEntity()

    if ( self.linkEntity == nil ) then
        return
    end

    EntityService:RemoveEntity(self.linkEntity)
    self.linkEntity = nil
end

function tower_drone_attack_with_slots:RepositionLinkEntity()

    if ( self.linkEntity == nil or self.pointEntity == nil ) then
        return
    end

    local selfPosition = EntityService:GetPosition(self.entity)
    local pointPosition = EntityService:GetPosition(self.pointEntity)

    local direction = VectorMulByNumber( Normalize( VectorSub( pointPosition, selfPosition ) ), 2.0 )
    selfPosition = VectorAdd(selfPosition, direction)

    local lightningComponent = EntityService:GetComponent(self.linkEntity, "LightningComponent")
    if ( lightningComponent == nil ) then
        return
    end

    local lightningComponentRef = reflection_helper(lightningComponent)
    if ( lightningComponentRef == nil or lightningComponentRef.lighning_vec == nil ) then
        return
    end

    local container = rawget(lightningComponentRef.lighning_vec, "__ptr");

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

    self.dronePointSelected = self.dronePointSelected or false

    if ( self.dronePointSelected ) then
        lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link_selected"
    else
        lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link"
    end
end

function tower_drone_attack_with_slots:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == true) then

        self:GettingInfoFromBaseToUpgrade(eventEntity)
    else
        self:GettingInfoFromRuin()
    end
end

function tower_drone_attack_with_slots:GettingInfoFromBaseToUpgrade(eventEntity)

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

        local baseDatabase = EntityService:GetOrCreateDatabase( entity )
        if ( baseDatabase == nil ) then
            goto continue
        end

        local newPositionX = 0
        local newPositionZ = 0

        if ( baseDatabase and baseDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = baseDatabase:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function tower_drone_attack_with_slots:GettingInfoFromRuin()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

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

        local ruinDatabase = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( ruinDatabase == nil ) then
            goto continue
        end

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local newPositionX = 0
        local newPositionZ = 0

        if ( ruinDatabase and ruinDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = ruinDatabase:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        self.slotItemsFromRuins = self.slotItemsFromRuins or {}

        local blueprint = ResourceManager:GetBlueprint( selfBlueprintName )

        if ( blueprint ~= nil ) then
            local equipmentComponent = blueprint:GetComponent("EquipmentComponent")
            if ( equipmentComponent ~= nil ) then

                local equipment = reflection_helper( equipmentComponent ).equipment[1]

                local slots = equipment.slots
                for i=1,slots.count do

                    local slot = slots[i]

                    local databaseParameter = selfLowName .. "_" .. slot.name

                    local modItemBlueprintName = ruinDatabase:GetStringOrDefault(databaseParameter, "") or ""

                    local towerDroneBlueprintName = ""

                    if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
                        towerDroneBlueprintName = modItemBlueprintName
                    end

                    self.slotItemsFromRuins[databaseParameter] = towerDroneBlueprintName
                end
            end
        end

        ::continue::
    end
end

function tower_drone_attack_with_slots:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetWasSold() == true) then
        return
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

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

        local ruinDatabase = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( ruinDatabase == nil ) then
            goto continue
        end

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local pointPosition = EntityService:GetPosition( self.pointEntity )
        local selfPosition = EntityService:GetPosition( self.entity )

        local pointPositionVector = {
            x = pointPosition.x - selfPosition.x,
            y = 0,
            z = pointPosition.z - selfPosition.z
        }

        ruinDatabase:SetVector(selfLowName .. "_center_point_vector", pointPositionVector)

        local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
        if ( equipmentComponent ~= nil ) then

            local equipment = reflection_helper( equipmentComponent ).equipment[1]

            local slots = equipment.slots
            for i=1,slots.count do

                local slot = slots[i]

                local towerDroneBlueprintName = DEFAULT_TOWER_ATTACK_DRONE_BLUEPRINT

                local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
                if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                    towerDroneBlueprintName = EntityService:GetBlueprintName( modItem )
                end

                local databaseParameter = selfLowName .. "_" .. slot.name

                ruinDatabase:SetString(databaseParameter, towerDroneBlueprintName)
            end
        else
            self.slotItemsFromRuins = self.slotItemsFromRuins or {}

            local blueprint = ResourceManager:GetBlueprint( selfBlueprintName )
            if ( blueprint ~= nil ) then
                local equipmentComponent = blueprint:GetComponent("EquipmentComponent")
                if ( equipmentComponent ~= nil ) then

                    local equipment = reflection_helper( equipmentComponent ).equipment[1]

                    local slots = equipment.slots
                    for i=1,slots.count do

                        local slot = slots[i]

                        local databaseParameter = selfLowName .. "_" .. slot.name

                        if ( self.slotItemsFromRuins[databaseParameter] and self.slotItemsFromRuins[databaseParameter] ~= nil and self.slotItemsFromRuins[databaseParameter] ~= "" ) then

                            ruinDatabase:SetString(databaseParameter, tostring(self.slotItemsFromRuins[databaseParameter]))
                        end
                    end
                end
            end
        end

        ::continue::
    end
end

-- #endregion Drone Point

function tower_drone_attack_with_slots:OnRelease()

    self:RemoveLinkEntity()

    if ( self.pointEntity ~= nil ) then

        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease(self)
    end
end

function tower_drone_attack_with_slots:_OnBuildingModifiedEvent()

    if ( drone_spawner_building._OnBuildingModifiedEvent ) then
        drone_spawner_building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:OnBuildingStart()

    if ( drone_spawner_building.OnBuildingStart ) then
        drone_spawner_building.OnBuildingStart(self)
    end

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:OnBuildingEnd()

    if ( drone_spawner_building.OnBuildingEnd ) then
        drone_spawner_building.OnBuildingEnd(self)
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    self.slotItemsFromRuins = self.slotItemsFromRuins or {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ~= nil ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local databaseParameter = selfLowName .. "_" .. slot.name

            local modItemBlueprintName = self.slotItemsFromRuins[databaseParameter] or ""

            if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then

                local item = ItemService:GetFirstItemForBlueprint( self.entity, modItemBlueprintName )

                if ( item == INVALID_ID ) then
                    item = ItemService:AddItemToInventory( self.entity, modItemBlueprintName )
                end

                if ( item ~= INVALID_ID ) then

                    ItemService:EquipItemInSlot( self.entity, item, slot.name )
                end
            end
        end
    end

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:SetMenuVisible(self.menuEntity)
end

function tower_drone_attack_with_slots:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:SetMenuVisible(self.menuEntity)
end

function tower_drone_attack_with_slots:SetMenuVisible(menuEntity)

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showMenu
    end

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", visible)
    end
end

function tower_drone_attack_with_slots:CreateMenuEntity()

    local menuBlueprintName = "misc/tower_drone_attack_slots_menu"

    if ( self.menuEntity ~= nil and not EntityService:IsAlive(self.menuEntity) ) then
        self.menuEntity = nil
    end

    if ( self.menuEntity ~= nil ) then

        local menuParent = EntityService:GetParent( self.menuEntity )

        if ( menuParent == nil or menuParent == INVALID_ID or menuParent ~= self.entity ) then
            self.menuEntity = nil
        end
    end

    if ( self.menuEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.menuEntity = child

                break
            end
        end
    end

    if ( self.menuEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)
    end

    if ( self.menuEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= self.menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( self.menuEntity == nil or self.menuEntity == INVALID_ID or not EntityService:IsAlive( self.menuEntity ) ) then
        self.menuEntity = nil
        return
    end

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.menuEntity, 0, sizeSelf.y, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( self.menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function tower_drone_attack_with_slots:PopulateSpecialActionInfo()

    local menuEntity = self.menuEntity
    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB == nil ) then
        return
    end

    menuDB:SetInt("slot_visible_1", 0)
    menuDB:SetInt("slot_visible_2", 0)
    menuDB:SetInt("slot_visible_3", 0)

    menuDB:SetString("slot_icon_1", "")
    menuDB:SetString("slot_icon_2", "")
    menuDB:SetString("slot_icon_3", "")

    menuDB:SetString("slot_name_1", "")
    menuDB:SetString("slot_name_2", "")
    menuDB:SetString("slot_name_3", "")

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent == nil ) then
        menuDB:SetInt("menu_visible", 0)
        return
    end

    local equipment = reflection_helper( equipmentComponent ).equipment[1]

    local slotsCount = 1

    local slots = equipment.slots
    for i=1,slots.count do

        local slot = slots[i]

        local blueprintName = DEFAULT_TOWER_ATTACK_DRONE_BLUEPRINT

        local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
        if ( modItem ~= nil and modItem ~= INVALID_ID ) then
            blueprintName = EntityService:GetBlueprintName( modItem )
        end

        local blueprint = ResourceManager:GetBlueprint( blueprintName )
        if ( blueprint ~= nil ) then

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
            if ( inventoryItemComponent ~= nil ) then

                local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                menuDB:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                menuDB:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                menuDB:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)

                slotsCount = slotsCount + 1
            end
        end
    end

    self:SetMenuVisible(menuEntity)
end

return tower_drone_attack_with_slots
