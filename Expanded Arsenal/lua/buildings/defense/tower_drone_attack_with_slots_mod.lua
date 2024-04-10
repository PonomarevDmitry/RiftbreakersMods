require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

-- original lua by ponomaryow.dmitry. slightly edited by WirawanMYT

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_drone_attack_with_slots_mod' ( drone_spawner_building )

local DEFAULT_TOWER_ATTACK_DRONE_BLUEPRINT = "items/tower_attack_drones/drone_attack_acid";

local DRONE_FADE_TIME = 0.3

function tower_drone_attack_with_slots_mod:__init()
    drone_spawner_building.__init(self,self)
end

function tower_drone_attack_with_slots_mod:OnInit()

	drone_spawner_building.OnInit(self)

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    if ( PlayerService:IsInFighterMode( owner ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self.data:SetString("action_icon", "gui/menu/research/icons/towers_drone_attack" )

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots_mod:OnLoad()

    drone_spawner_building.OnLoad(self)

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self.showMenu = self.showMenu or 0

    self.data:SetString("action_icon", "gui/menu/research/icons/towers_drone_attack" )

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots_mod:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function tower_drone_attack_with_slots_mod:SpawnDrones()

    drone_spawner_building.CleanupDrones(self);

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
            droneIdx = droneIdx + 1
            Insert( self.drones, drone )

            self:UpdateActiveDrones( drone, isActive )
        end
    end
end

function tower_drone_attack_with_slots_mod:GetDronesTemplatesArray()

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
                local blueprintDatabase = EntityService:GetBlueprintDatabase( modItem ) or EntityService:GetDatabase( modItem )

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

function tower_drone_attack_with_slots_mod:OnItemEquippedEvent( evt )

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

function tower_drone_attack_with_slots_mod:OnItemUnequippedEvent( evt )

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

function tower_drone_attack_with_slots_mod:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == false) then
        self:GettingInfoFromRuin()
    end
end

function tower_drone_attack_with_slots_mod:GettingInfoFromRuin()

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

function tower_drone_attack_with_slots_mod:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

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

function tower_drone_attack_with_slots_mod:_OnBuildingModifiedEvent()

    drone_spawner_building._OnBuildingModifiedEvent(self)

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots_mod:OnBuildingStart()

    drone_spawner_building.OnBuildingStart(self)

    self:PopulateSpecialActionInfo()
end

function tower_drone_attack_with_slots_mod:OnBuildingEnd()

    drone_spawner_building.OnBuildingEnd(self)

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

function tower_drone_attack_with_slots_mod:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:SetMenuVisible(self.menuEntity)
end

function tower_drone_attack_with_slots_mod:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:SetMenuVisible(self.menuEntity)
end

function tower_drone_attack_with_slots_mod:SetMenuVisible(menuEntity)

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

function tower_drone_attack_with_slots_mod:CreateMenuEntity()

    local menuBlueprintName = "misc/tower_drone_attack_slots_menu_mod"

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

    local menuDB = EntityService:GetDatabase( self.menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function tower_drone_attack_with_slots_mod:PopulateSpecialActionInfo()

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

return tower_drone_attack_with_slots_mod
