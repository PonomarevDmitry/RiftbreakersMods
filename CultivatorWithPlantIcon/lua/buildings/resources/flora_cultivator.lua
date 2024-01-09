require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'flora_cultivator' ( drone_spawner_building )

local DEFAULT_SAPLING_BLUEPRINT = "items/loot/saplings/biomas_sapling_item";

function flora_cultivator:__init()
    drone_spawner_building.__init(self,self)
end

function flora_cultivator:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit( self )
    end

    self.default_item = INVALID_ID

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )

    self.showPlantIcon = self.showPlantIcon or 1

    self:CreateProductionStateMachine()

    self:CreateCenterPoint()
    self:RegisterBuildMenuTracker()
end

function IsEquippedItemBlueprintValid( entity, new_blueprint )

    if new_blueprint ~= DEFAULT_SAPLING_BLUEPRINT and EntityService:GetBlueprintName( entity ) == DEFAULT_SAPLING_BLUEPRINT then
        return false
    end

    if not MissionService:IsCampaignBiome() then
        return true
    end

    local database = EntityService:GetBlueprintDatabase( entity )

    if database and database:HasString("biome_requirement") then

        local biome_name = MissionService:GetCurrentBiomeName()
        local biome_requirement = database:GetString("biome_requirement")

        if string.find(biome_requirement, biome_name) == nil then
            return false
        end
    end

    return true
end

function flora_cultivator:OnLoad()

    self.showPlantIcon = self.showPlantIcon or 0

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad( self )
    end

    if self.default_item ~= INVALID_ID then
        local default_blueprint = self:GetDefaultSaplingItem()
        if not IsEquippedItemBlueprintValid( self.default_item, default_blueprint ) then
            self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
        end

        if self.item and self.item ~= INVALID_ID then
            if not IsEquippedItemBlueprintValid( self.item, default_blueprint ) then
                ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
            end
        end
    end

    self:CreateProductionStateMachine()

    self:CreateCenterPoint()
    self:RegisterBuildMenuTracker()


    if ( EntityService:HasComponent( self.entity, "FloraCultivatorComponent") ) then

        EntityService:RemoveComponent( self.entity, "FloraCultivatorComponent")

        local db = EntityService:GetDatabase( self.item )

        if ( db and db:HasString("plant_prefab") ) then

            local plant_prefab = db:GetStringOrDefault( "plant_prefab", "" )

            self.spawn_prefab = BuildingService:CreateFloraCultivatorComponent( self.pointEntity, plant_prefab )
        end
    end
end

function flora_cultivator:RegisterBuildMenuTracker()

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent")

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function flora_cultivator:CreateProductionStateMachine()

    if ( self.fsm ~= nil ) then
        return
    end

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "update_production", { execute="OnUpdateProductionExecute", interval=1.0 } )
    self.fsm:ChangeState("update_production")
end

function flora_cultivator:CreateMenuEntity()

    self:RegisterBuildMenuTracker()

    if ( self.cultivatorSaplingMenu == nil ) then

        self.cultivatorSaplingMenu = EntityService:SpawnAndAttachEntity("misc/cultivator_sapling_menu", self.entity)

        local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )

        self.showPlantIcon = self.showPlantIcon or 1

        local visible = 0

        if ( BuildingService:IsBuildingFinished( self.entity ) ) then
            visible = self.showPlantIcon
        end

        menuDB:SetInt("sapling_visible", visible)
    end
end

function flora_cultivator:OnRelease()

    self:DestoryPlanIcon()

    self:RemoveLinkEntity()

    if ( self.pointEntity ~= nil ) then
        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease( self )
    end
end

function flora_cultivator:GetDefaultSaplingItem()

    local sapling_item = self.data:GetStringOrDefault("sapling_item", DEFAULT_SAPLING_BLUEPRINT)

    if sapling_item == DEFAULT_SAPLING_BLUEPRINT then
        local biome_default_item = "items/loot/saplings/biomas_sapling_" .. MissionService:GetCurrentBiomeName() .. "_item"

        if ResourceManager:ResourceExists( "EntityBlueprint", biome_default_item ) then
            return biome_default_item
        end
    end

    return sapling_item;
end

function flora_cultivator:OnBuildingStart()

    if ( drone_spawner_building.OnBuildingStart ) then
        drone_spawner_building.OnBuildingStart(self)
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:OnBuildingEnd()

    if ( drone_spawner_building.OnBuildingEnd ) then
        drone_spawner_building.OnBuildingEnd(self)
    end

    self:PopulateSpecialActionInfo()

    self:DisableVegetationAround();

    local default_blueprint = self:GetDefaultSaplingItem()

    self.default_item = ItemService:GetFirstItemForBlueprint( self.entity, default_blueprint )

    if self.default_item == INVALID_ID then
        self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
    end

    self.saplingFromRuins = self.saplingFromRuins or ""

    if ( self.saplingFromRuins ~= "" and self.saplingFromRuins ~= nil ) then

        self.item = ItemService:GetFirstItemForBlueprint( self.entity, self.saplingFromRuins )

        if self.item == INVALID_ID then
            self.item = ItemService:AddItemToInventory( self.entity, self.saplingFromRuins )
        end

        if ( self.item ~= INVALID_ID ) then
            if not ItemService:IsSameSubTypeEquipped( self.entity, self.item ) then
                LogService:Log(" OnBuildingEnd EquipItemInSlot self.item ")
                ItemService:EquipItemInSlot( self.entity, self.item, "MOD_1" )
                return
            end
        end
    end

    if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
        LogService:Log(" OnBuildingEnd EquipItemInSlot self.default_item ")
        ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
    end
end

function flora_cultivator:_OnBuildingModifiedEvent()

    if ( drone_spawner_building._OnBuildingModifiedEvent ) then
        drone_spawner_building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:OnActivate()

    LogService:Log(" OnActivate ")

    if ( self.item ~= INVALID_ID and self.item ~= nil ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.item ) then
            LogService:Log(" OnActivate EquipItemInSlot self.item ")
            ItemService:EquipItemInSlot( self.entity, self.item, "MOD_1" )
        end
    elseif ( self.default_item ~= INVALID_ID and self.default_item ~= nil ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
            LogService:Log(" OnActivate EquipItemInSlot self.default_item ")
            ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
        end
    end

    if ( drone_spawner_building.OnActivate ) then
        drone_spawner_building.OnActivate(self)
    end

    self:RefreshDrones()
end

function flora_cultivator:PopulateSpecialActionInfo()

    self:OnUpdateProductionExecute()

    if ( self.item == INVALID_ID or self.item == nil ) then

        self.data:SetString("action_icon", "gui/hud/tools_icons/sapling" )
        self:DestoryPlanIcon()
        return
    end

    local material = ItemService:GetItemIcon( self.item )

    if ( not IsNullOrEmpty( material ) ) then
        self.data:SetString("action_icon", material )
    else
        self.data:SetString("action_icon", "gui/hud/tools_icons/sapling" )
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )
    if ( IsNullOrEmpty( blueprintName ) ) then
        self:DestoryPlanIcon()
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then
        self:DestoryPlanIcon()
        return
    end

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp == nil ) then
        self:DestoryPlanIcon()
        return
    end

    local inventoryCompRef = reflection_helper(inventoryComp)
    if ( inventoryCompRef == nil ) then
        self:DestoryPlanIcon()
        return
    end

    local saplingIcon = inventoryCompRef.icon
    local saplingName = inventoryCompRef.name

    self:CreateMenuEntity()

    local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
    menuDB:SetString("sapling_icon", saplingIcon)
    menuDB:SetString("sapling_name", saplingName)

    self.showPlantIcon = self.showPlantIcon or 1

    local visible = 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showPlantIcon
    end

    menuDB:SetInt("sapling_visible", visible)
end

function flora_cultivator:RefreshDrones()
    for drone in Iter(self.drones) do
        self:DroneSpawned(drone)
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:DroneSpawned(drone)

    if ( drone_spawner_building.DroneSpawned ) then
        drone_spawner_building.DroneSpawned( self, drone )
    end

    local db = EntityService:GetDatabase( drone )
    if db ~= nil then
        db:SetString( "plant_blueprint", self.spawn_blueprint or "" )
        db:SetString( "plant_prefab", self.spawn_prefab or "" )
        db:SetString( "cultivate_target", self.cultivate_target or "" )
    end
end

function flora_cultivator:OnLuaGlobalEvent( evt )

    local eventName = evt:GetEvent()

    if eventName == "CultivationEnded" then
        self.cultivate_target = nil;
        self:RefreshDrones()
    elseif eventName == "CultivateSapling" then
        local sapling_item = evt:GetDatabase():GetString("sapling_item")
        self.data:SetString("sapling_item", sapling_item )
        self.default_item = ItemService:AddItemToInventory( self.entity, sapling_item)
        ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )

        self:RefreshDrones()
    else
        local tokens = Split(eventName, "@");
        if #tokens == 2 then
            if tokens[1] == "CultivatePlant" then
                local entity = FindService:FindEntityByName(tokens[2] )
                if entity ~= INVALID_ID then
                    self.cultivate_target = tokens[2]
                    self:RefreshDrones()
                end
            end
        end
    end
end

function flora_cultivator:DisableVegetationAround()
    local drone_search_radius = self.data:GetFloatOrDefault( "drone_search_radius", 25.0 )

    self.predicate = self.predicate or {
        signature = "VegetationLifecycleEnablerComponent"
    }

    local entities = FindService:FindEntitiesByPredicateInRadius( self.pointEntity, drone_search_radius, self.predicate )

    for entity in Iter( entities ) do
        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent")
    end
end

function flora_cultivator:OnItemEquippedEvent( evt )

    LogService:Log(" OnItemEquippedEvent ")

    self.item = evt:GetItem()
    if ( EntityService:IsAlive(self.item) == false ) then
        LogService:Log(" OnItemEquippedEvent EntityService:IsAlive(self.item) == false")
        return
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )

    LogService:Log(" OnItemEquippedEvent blueprintName " .. tostring(blueprintName))

    local playerForEntity = self:GetPlayerForEntity(self.entity)
    if ( playerForEntity ~= nil and playerForEntity ~= INVALID_ID ) then

        local selector = PlayerService:GetPlayerSelector( playerForEntity )

        if ( selector ~= nil and selector ~= INVALID_ID ) then
            local selectorDB = EntityService:GetDatabase( selector )

            self:AddSaplingToLastList(blueprintName, selectorDB)
        end
    end

    local db = EntityService:GetDatabase( self.item )
    if( db == nil ) then
        return
    end

    if db:HasString("plant_blueprint") then
        self.spawn_blueprint = db:GetStringOrDefault( "plant_blueprint", "" )
        EntityService:RemoveComponent( self.pointEntity, "FloraCultivatorComponent")
    else
        self.spawn_blueprint = nil
    end

    local plant_prefab = ""

    if db:HasString("plant_prefab") then

        plant_prefab = db:GetStringOrDefault( "plant_prefab", "" )

        LogService:Log(" OnItemEquippedEvent plant_prefab " .. tostring(plant_prefab))

        self.spawn_prefab = BuildingService:CreateFloraCultivatorComponent( self.pointEntity, plant_prefab )
    else
        self.spawn_prefab = nil
    end

    Assert( (self.spawn_blueprint or self.spawn_prefab) ~= nil, "ERROR: missing plant info! " .. db:GetStringOrDefault( "plant_prefab", "" ) .. " " .. db:GetStringOrDefault( "plant_blueprint", "" ) );

    self:DisableVegetationAround();
    self:RefreshDrones()
end

function flora_cultivator:GetPlayerForEntity( entity )

    if ( PlayerService.GetPlayerForEntity ) then
        return PlayerService:GetPlayerForEntity( entity )
    end

    return 0
end

-- #region Sapling List

function flora_cultivator:AddSaplingToLastList(selectedBlueprintName, selectorDB)

    if ( selectedBlueprintName == "" or selectedBlueprintName == nil ) then
        return
    end

    local parameterName = "cultivator_sapling_picker_tool.last_selected_saplings"

    local currentListArray = self:GetCurrentList(parameterName, selectorDB)

    if ( IndexOf( currentListArray, selectedBlueprintName ) ~= nil ) then
        Remove( currentListArray, selectedBlueprintName )
    end

    Insert( currentListArray, selectedBlueprintName )






    while ( #currentListArray > 20 ) do

        table.remove( currentListArray, 1 )
    end

    local currentListString = table.concat( currentListArray, "|" )

    if ( selectorDB ) then
        selectorDB:SetString(parameterName, currentListString)
    end
end

function flora_cultivator:GetCurrentList(parameterName, selectorDB)

    local currentListString = self:GetCurrentListString(parameterName, selectorDB)

    local currentListArray = Split( currentListString, "|" )

    return currentListArray
end

function flora_cultivator:GetCurrentListString(parameterName, selectorDB)

    local currentList = ""

    if ( selectorDB and selectorDB:HasString(parameterName) ) then

        currentList = selectorDB:GetStringOrDefault( parameterName, "" ) or ""
    end

    return currentList
end

-- #endregion Sapling List

function flora_cultivator:DestoryPlanIcon()

    if ( self.cultivatorSaplingMenu == nil ) then
        return
    end

    EntityService:RemoveEntity( self.cultivatorSaplingMenu )
    self.cultivatorSaplingMenu = nil
end

function flora_cultivator:OnEnterBuildMenuEvent( evt )

    self.showPlantIcon = 1

    self:SetCultivatorSaplingMenuVisible()
end

function flora_cultivator:OnEnterFighterModeEvent( evt )

    self.showPlantIcon = 0

    self:SetCultivatorSaplingMenuVisible()
end

function flora_cultivator:SetCultivatorSaplingMenuVisible()

    self:CreateMenuEntity()

    local visible = 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showPlantIcon
    end

    local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
    menuDB:SetInt("sapling_visible", visible)
end

function flora_cultivator:OnUpdateProductionExecute()

    if ( self.item == INVALID_ID or self.item == nil ) then

        self.data:SetString( "stat_categories", "" )
        return
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )
    if ( IsNullOrEmpty( blueprintName ) ) then

        self.data:SetString( "stat_categories", "" )
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        self.data:SetString( "stat_categories", "" )
        return
    end

    local blueprint = ResourceManager:GetBlueprint( blueprintName )
    if ( blueprint == nil ) then

        self.data:SetString( "stat_categories", "" )
        return
    end

    local productionGroupContent = ""

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp ~= nil ) then

        local inventoryCompRef = reflection_helper(inventoryComp)

        if ( inventoryCompRef ~= nil ) then

            productionGroupContent = "plant"

            self.data:SetString("production_group.rows.plant.name", inventoryCompRef.name )
            self.data:SetString("production_group.rows.plant.icon", "gui/hud/tools_icons/sapling" )
            self.data:SetString("production_group.rows.plant.value",  "" )
        end
    end

    local gatherComp = blueprint:GetComponent("GatherResourceComponent")

    if ( gatherComp ~= nil ) then

        local gatherCompRef = reflection_helper(gatherComp)

        if ( gatherCompRef ~= nil and gatherCompRef.resources ~= nil and gatherCompRef.resources.resource ~= nil and gatherCompRef.resources.resource.count > 0 ) then

            local resourceNamesList = {
                "biomass_plant",
                "biomass_animal",

                "carbonium",
                "steel",

                "cobalt",
                "palladium",

                "uranium_ore",
                "uranium",

                "titanium",

                "rhodonite",
                "tanzanite",
                "hazenite",
                "ferdonite"
            }

            for resourceName in Iter( resourceNamesList ) do

                if ( self:IsResourceInGatherable( resourceName, gatherCompRef.resources.resource ) ) then

                    productionGroupContent = self:AddResourceToProductionGroup(resourceName, productionGroupContent)
                end
            end
        end
    end

    self.data:SetString("stat_categories", "production_group")
    self.data:SetString("production_group.rows", productionGroupContent )
end

function flora_cultivator:AddResourceToProductionGroup( resourceName, productionGroupContent )

    local resourceBlueprintName = ItemService:GetResourceBlueprint( resourceName )
    if ( resourceBlueprintName == "" or resourceBlueprintName == nil ) then
        return productionGroupContent
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", resourceBlueprintName ) ) then
        return productionGroupContent
    end

    local resourceBlueprint = ResourceManager:GetBlueprint( resourceBlueprintName )
    if ( resourceBlueprint == nil ) then
        return productionGroupContent
    end

    local resourceInventoryComp = resourceBlueprint:GetComponent( "InventoryItemComponent" )
    if ( resourceInventoryComp == nil ) then
        return productionGroupContent
    end

    local resourceInventoryCompRef = reflection_helper( resourceInventoryComp )
    if ( resourceInventoryCompRef == nil ) then
        return productionGroupContent
    end

    if ( string.len(productionGroupContent) > 0 ) then
        productionGroupContent = productionGroupContent .. ","
    end

    productionGroupContent = productionGroupContent .. resourceName

    self.data:SetString("production_group.rows." .. resourceName .. ".name", resourceInventoryCompRef.name )
    self.data:SetString("production_group.rows." .. resourceName .. ".icon", resourceInventoryCompRef.icon )
    self.data:SetString("production_group.rows." .. resourceName .. ".value",  "" )

    return productionGroupContent
end

function flora_cultivator:IsResourceInGatherable( resourceName, resourceList )

    local hashResource = CalcHash(resourceName)

    local count = resourceList.count

    for i=1,count do

        local resourcePair = resourceList[i]

        if ( resourcePair ~= nil and resourcePair.key ~= nil and resourcePair.key.hash ~= nil and resourcePair.key.hash == hashResource ) then

            return true
        end
    end

    return false
end

-- #region Drone Point

function flora_cultivator:CreateCenterPoint()

    if ( self.pointEntity == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = self.data:GetFloatOrDefault("center_point_entity_x", transform.position.x)
        local newPositionZ = self.data:GetFloatOrDefault("center_point_entity_z", transform.position.z)

        local team = EntityService:GetTeam( self.entity )
        self.pointEntity = EntityService:SpawnAndAttachEntity( "misc/area_center_point", self.entity, team )

        ItemService:SetInvisible(self.pointEntity, true)

        self:SetCenterPointPosition( newPositionX, newPositionZ )
    end

    EntityService:SetName( self.pointEntity, "center_point_entity" )

    self.data:SetInt("center_point_entity", self.pointEntity)
end

function flora_cultivator:OnDronePointEvent(evt)

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

function flora_cultivator:OnActivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = true

    self:UpdateDronePointSkinMaterial()
end

function flora_cultivator:OnDeactivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = false

    self:UpdateDronePointSkinMaterial()
end

function flora_cultivator:SetCenterPointPosition( newPositionX, newPositionZ )

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

function flora_cultivator:UpdateDisplayRadiusVisibility( show, entity )

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

function flora_cultivator:UpdateDronePointSkinMaterial()

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

function flora_cultivator:CreateLinkEntity()

    if ( self.linkEntity ~= nil ) then
        return
    end

    local team = EntityService:GetTeam( self.entity )
    self.linkEntity = EntityService:SpawnAndAttachEntity( "effects/area_center_point_effects/flora_cultivator_area_center_point_link", self.entity, team)

    ItemService:SetInvisible(self.linkEntity, true)
end

function flora_cultivator:RemoveLinkEntity()

    if ( self.linkEntity == nil ) then
        return
    end

    EntityService:RemoveEntity(self.linkEntity)
    self.linkEntity = nil
end

function flora_cultivator:RepositionLinkEntity()

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

function flora_cultivator:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == true) then

        self:GettingInfoFromBaseToUpgrade(eventEntity)
    else
        self:GettingInfoFromRuin()
    end
end

function flora_cultivator:GettingInfoFromBaseToUpgrade(eventEntity)

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

function flora_cultivator:GettingInfoFromRuin()

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
            LogService:Log("GettingInfoFromRuin blueprintName ~= selfRuinsBlueprint")
            goto continue
        end

        local ruinPosition = EntityService:GetPosition(ruinEntity)
        if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
            LogService:Log("GettingInfoFromRuin ruinPosition.x ~= position.x")
            goto continue
        end

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            LogService:Log("GettingInfoFromRuin ruinDatabaseBlueprint ~= selfBlueprintName")
            goto continue
        end

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = ruinDatabase:GetFloatOrDefault("center_point_entity_x", transform.position.x)
        local newPositionZ = ruinDatabase:GetFloatOrDefault("center_point_entity_z", transform.position.z)

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        self.saplingFromRuins = ""

        local modItemBlueprintName = ruinDatabase:GetStringOrDefault("flora_cultivator_MOD_1", "") or ""

        LogService:Log("GettingInfoFromRuin modItemBlueprintName " .. tostring(modItemBlueprintName))

        if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
            self.saplingFromRuins = modItemBlueprintName
        end

        ::continue::
    end
end

function flora_cultivator:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

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

        local modItemBlueprintName = ""

        local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )

        if ( modItem ~= nil and modItem ~= INVALID_ID ) then
            modItemBlueprintName = EntityService:GetBlueprintName(modItem)
        end

        LogService:Log("OnBuildingRemovedEventTrasferingInfoToRuin GetEquippedItem modItem " .. tostring(modItem) .. " modItemBlueprintName " .. tostring(modItemBlueprintName))

        ruinDatabase:SetString("flora_cultivator_MOD_1", modItemBlueprintName)

        ::continue::
    end
end

-- #endregion Drone Point

function flora_cultivator:OnLuaGlobalEventCultivatorShowHideIcon()
    -- Legacy Empty function
end

return flora_cultivator
