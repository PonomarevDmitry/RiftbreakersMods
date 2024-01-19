require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_mine_layer_with_slots' ( drone_spawner_building )

local DEFAULT_TOWER_MINE_BLUEPRINT = "items/tower_mines/drone_mine_root"

function tower_mine_layer_with_slots:__init()
    drone_spawner_building.__init(self,self)
end

function tower_mine_layer_with_slots:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self.lifting_drones = 0

    self:CreateCenterPoint()
    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self:FillMinesArrays()

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    if ( PlayerService:IsInFighterMode( owner ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self.data:SetString("action_icon", "gui/menu/research/icons/mech_basic_equipment" )

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateCenterPoint()
    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self:FillMinesArrays()

    self.showMenu = self.showMenu or 0

    self.data:SetString("action_icon", "gui/menu/research/icons/mech_basic_equipment" )

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:FillMinesArrays()

    self.blueprintArray = {
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

    self.researchesForMinesHash = {

        ["items/tower_mines/drone_mine_root_acid"] = "gui/menu/research/name/mech_weapons_corrosive_gun_standard",
        ["items/tower_mines/drone_mine_root_cryogenic"] = "gui/menu/research/name/consumable_proximity_mine_cryo_standard",
        ["items/tower_mines/drone_mine_root_energy"] = "gui/menu/research/name/mech_weapons_energy_standard",
        ["items/tower_mines/drone_mine_root_incendiary"] = "gui/menu/research/name/mech_weapons_liquid_advanced",

        ["items/tower_mines/drone_mine_root_nuclear"] = "gui/menu/research/name/consumable_nuclear_mine_standard",
        ["items/tower_mines/drone_mine_root_sonic"] = "gui/menu/research/name/consumable_sonic_grenades_standard",
    }

    self.globalAwardsForMinesHash = {

        ["items/tower_mines/drone_mine_root_holo_decoy"] = {

            "items/consumables/holo_decoy_standard_item",
            "items/consumables/holo_decoy_advanced_item",
            "items/consumables/holo_decoy_superior_item",
            "items/consumables/holo_decoy_extreme_item"
        },

        ["items/tower_mines/drone_mine_root_gravity"] = {

            "items/consumables/proximity_mine_gravity_standard_item",
            "items/consumables/proximity_mine_gravity_advanced_item",
            "items/consumables/proximity_mine_gravity_superior_item",
            "items/consumables/proximity_mine_gravity_extreme_item"
        }
    }
end

function tower_mine_layer_with_slots:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( self.entity, "OperateActionMenuEvent", "OnOperateActionMenuEvent")

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
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

    local isActive = ( self.data:GetIntOrDefault( "activated", 0 ) == 1 )

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

function tower_mine_layer_with_slots:EquipEmptySlots()

    local default_item = ItemService:GetFirstItemForBlueprint( self.entity, DEFAULT_TOWER_MINE_BLUEPRINT )

    if ( default_item == INVALID_ID ) then
        default_item = ItemService:AddItemToInventory( self.entity, DEFAULT_TOWER_MINE_BLUEPRINT )
    end

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem == nil or modItem == INVALID_ID ) then

                ItemService:EquipItemInSlot( self.entity, default_item, slot.name )
            end
        end
    end
end

function tower_mine_layer_with_slots:GetMinesArray()

    local DEFAULT_MINE_BLUEPRINT = "units/drones/drone_mine_root"

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

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                local blueprintDatabase = EntityService:GetBlueprintDatabase( modItem ) or EntityService:GetDatabase( modItem )

                if ( blueprintDatabase and blueprintDatabase:HasString("mine_blueprint") ) then

                    mineBlueprint = blueprintDatabase:GetString("mine_blueprint")
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

    local slotName = evt:GetSlot()
    local item = evt:GetItem()

    local itemBlueprintName = ""

    if ( item ~= nil and item ~= INVALID_ID ) then
        itemBlueprintName = EntityService:GetBlueprintName(item)
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetDatabase( self.entity )
    database:SetString(key, itemBlueprintName)

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:OnItemUnequippedEvent( evt )

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnDrones()
    end

    local slotName = evt:GetSlot()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetDatabase( self.entity )
    database:SetString(key, "")

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:OnOperateActionMenuEvent()

    self:AddMinesItemsToEntity(self.entity)

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    local player = PlayerService:GetPlayerControlledEnt( owner )

    self:AddMinesItemsToEntity(player)
end

function tower_mine_layer_with_slots:AddMinesItemsToEntity(entity)

    for blueprintName in Iter( self.blueprintArray ) do

        local isMineUnlocked = self:IsMineUnlocked(blueprintName)
        if ( not isMineUnlocked ) then
            goto continue
        end

        local item = ItemService:GetFirstItemForBlueprint( entity, blueprintName )
        if ( item ~= INVALID_ID and item ~= nil) then
            goto continue
        end

        ItemService:AddItemToInventory( entity, blueprintName )

        ::continue::
    end
end

function tower_mine_layer_with_slots:IsMineUnlocked(blueprintName)

    local researchName = self.researchesForMinesHash[blueprintName]
    local globalAwardList = self.globalAwardsForMinesHash[blueprintName]

    if ( researchName ~= nil and researchName ~= "" ) then

        return PlayerService:IsResearchUnlocked( researchName )
    end

    if ( globalAwardList ~= nil ) then

        for itemName in Iter( globalAwardList ) do

            if ( PlayerService:HasGlobalAward( itemName ) ) then
                return true
            end
        end

        return false
    end

    return true
end

-- #region Drone Point

function tower_mine_layer_with_slots:CreateCenterPoint()

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

                goto continue
            end
        end

        ::continue::
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

function tower_mine_layer_with_slots:OnDronePointEvent(evt)

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
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )

            local component = reflection_helper( EntityService:CreateComponent(self.pointEntity,"DisplayRadiusComponent") )
            component.min_radius = self.display_radius_size.min
            component.max_radius = self.display_radius_size.max
            component.max_radius_blueprint = self.display_effect_blueprint

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

function tower_mine_layer_with_slots:SetPointEntitySelectedSkin()

    self.dronePointSelected = self.dronePointSelected or false

    local isSkinned = EntityService:IsSkinned(self.pointEntity)

    if ( self.dronePointSelected ) then
        if ( isSkinned ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
        end
    else
        if ( isSkinned ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_blue", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
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
        self:SetPointEntitySelectedSkin()
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

    local container = rawget(lightningComponent.lighning_vec, "__ptr")

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

function tower_mine_layer_with_slots:GettingInfoFromRuin()

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

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )
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

        self.slotItemsFromRuins = {}

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

                    local towerMineBlueprintName = ""

                    if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
                        towerMineBlueprintName = modItemBlueprintName
                    end

                    self.slotItemsFromRuins[databaseParameter] = towerMineBlueprintName
                end
            end
        end

        ::continue::
    end
end

function tower_mine_layer_with_slots:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

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

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )
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

                local towerMineBlueprintName = DEFAULT_TOWER_MINE_BLUEPRINT

                local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
                if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                    towerMineBlueprintName = EntityService:GetBlueprintName( modItem )
                end

                local databaseParameter = selfLowName .. "_" .. slot.name

                ruinDatabase:SetString(databaseParameter, towerMineBlueprintName)
            end
        end

        ::continue::
    end
end

-- #endregion Drone Point

function tower_mine_layer_with_slots:OnRelease()

    if ( self.menuEntity ~= nil ) then
        EntityService:RemoveEntity( self.menuEntity )
        self.menuEntity = nil
    end

    self:RemoveLinkEntity()

    if ( self.pointEntity ~= nil ) then
        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease( self )
    end
end

function tower_mine_layer_with_slots:_OnBuildingModifiedEvent()

    if ( drone_spawner_building._OnBuildingModifiedEvent ) then
        drone_spawner_building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:OnBuildingStart()

    if ( drone_spawner_building.OnBuildingStart ) then
        drone_spawner_building.OnBuildingStart(self)
    end

    self:PopulateSpecialActionInfo()
end

function tower_mine_layer_with_slots:OnBuildingEnd()

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

function tower_mine_layer_with_slots:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:SetMenuVisible(self.menuEntity)
end

function tower_mine_layer_with_slots:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:SetMenuVisible(self.menuEntity)
end

function tower_mine_layer_with_slots:SetMenuVisible(menuEntity)

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local visible = 0

    self.showMenu = self.showMenu or 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showMenu
    end

    local menuDB = EntityService:GetDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", visible)
    end
end

function tower_mine_layer_with_slots:CreateMenuEntity()

    local menuBlueprintName = "misc/tower_mine_layer_slots_menu"

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
                goto continue
            end
        end

        ::continue::
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

    local menuDB = EntityService:GetDatabase( self.menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function tower_mine_layer_with_slots:PopulateSpecialActionInfo()

    local menuEntity = self.menuEntity
    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    local menuDB = EntityService:GetDatabase( menuEntity )
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

        local blueprintName = DEFAULT_TOWER_MINE_BLUEPRINT

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

return tower_mine_layer_with_slots
