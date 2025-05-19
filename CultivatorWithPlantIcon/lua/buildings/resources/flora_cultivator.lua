require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

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

    self:RegisterBuildMenuTracker()

    local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )
    if ( modItem ~= nil and modItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( self.entity )
        if ( database ~= nil ) then
            local selfLowName = BuildingService:FindLowUpgrade( EntityService:GetBlueprintName(self.entity) )
            database:SetString(selfLowName .. "_MOD_1", EntityService:GetBlueprintName(modItem))
        end
    end

    self:PopulateSpecialActionInfo()

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        self:SpawnLandingSpots()
        self:SpawnDrones()
    else
        self:RefreshDrones()
    end
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
                self:PopulateSpecialActionInfo()
            end
        end
    end

    self:CreateProductionStateMachine()

    self:RegisterBuildMenuTracker()

    local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )
    if ( modItem ~= nil and modItem ~= INVALID_ID ) then

        local database = EntityService:GetDatabase( self.entity )
        if ( database ~= nil ) then
            local selfLowName = BuildingService:FindLowUpgrade( EntityService:GetBlueprintName(self.entity) )
            database:SetString(selfLowName .. "_MOD_1", EntityService:GetBlueprintName(modItem))
        end
    end

    self:RefreshDrones()

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:RegisterBuildMenuTracker()

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )
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

    local cultivatorSaplingMenuBlueprintName = "misc/cultivator_sapling_menu"

    if ( self.cultivatorSaplingMenu ~= nil and not EntityService:IsAlive(self.cultivatorSaplingMenu) ) then
        self.cultivatorSaplingMenu = nil
    end

    if ( self.cultivatorSaplingMenu ~= nil ) then

        local menuParent = EntityService:GetParent( self.cultivatorSaplingMenu )

        if ( menuParent == nil or menuParent == INVALID_ID or menuParent ~= self.entity ) then
            self.cultivatorSaplingMenu = nil
        end
    end

    if ( self.cultivatorSaplingMenu == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == cultivatorSaplingMenuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.cultivatorSaplingMenu = child

                break
            end
        end
    end

    if ( self.cultivatorSaplingMenu == nil ) then

        self.cultivatorSaplingMenu = EntityService:SpawnAndAttachEntity(cultivatorSaplingMenuBlueprintName, self.entity)
    end

    if ( self.cultivatorSaplingMenu ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == cultivatorSaplingMenuBlueprintName and child ~= self.cultivatorSaplingMenu ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( self.cultivatorSaplingMenu == nil or self.cultivatorSaplingMenu == INVALID_ID or not EntityService:IsAlive( self.cultivatorSaplingMenu ) ) then
        self.cultivatorSaplingMenu = nil
        return
    end

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( self.cultivatorSaplingMenu, 0, sizeSelf.y, 0 )

    local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
    if ( menuDB == nil ) then
        return
    end

    self.showPlantIcon = self.showPlantIcon or 0

    local visible = 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showPlantIcon
    end

    menuDB:SetInt("sapling_visible", visible)
end

function flora_cultivator:OnRelease()

    self:DestoryPlanIcon()

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

    self:DisableVegetationAround();

    local default_blueprint = self:GetDefaultSaplingItem()

    self.default_item = ItemService:GetFirstItemForBlueprint( self.entity, default_blueprint )

    if self.default_item == INVALID_ID then
        self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
    end

    self.saplingFromRuins = self.saplingFromRuins or ""

    if ( self.saplingFromRuins ~= "" and self.saplingFromRuins ~= nil ) then

        local modItem = ItemService:GetFirstItemForBlueprint( self.entity, self.saplingFromRuins )

        if ( modItem == INVALID_ID ) then
            modItem = ItemService:AddItemToInventory( self.entity, self.saplingFromRuins )
        end

        if ( modItem ~= INVALID_ID ) then
            if ( IsEquippedItemBlueprintValid( modItem, default_blueprint ) ) then

                self.item = modItem

                ItemService:EquipItemInSlot( self.entity, modItem, "MOD_1" )
                self:PopulateSpecialActionInfo()
                return
            end
        end
    end

    if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
        ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:_OnBuildingModifiedEvent()

    if ( drone_spawner_building._OnBuildingModifiedEvent ) then
        drone_spawner_building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:OnActivate()

    if ( self.item ~= INVALID_ID and self.item ~= nil ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.item ) then
            ItemService:EquipItemInSlot( self.entity, self.item, "MOD_1" )
            self:PopulateSpecialActionInfo()
        end
    elseif ( self.default_item ~= INVALID_ID and self.default_item ~= nil ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
            ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
            self:PopulateSpecialActionInfo()
        end
    end

    if ( drone_spawner_building.OnActivate ) then
        drone_spawner_building.OnActivate(self)
    end

    self:RefreshDrones()
end

function flora_cultivator:PopulateSpecialActionInfo()

    self:OnUpdateProductionExecute()

    local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )

    if ( modItem == INVALID_ID or modItem == nil ) then

        self.data:SetString("action_icon", "gui/hud/tools_icons/sapling" )
        self:DestoryPlanIcon()
        return
    end

    local material = ItemService:GetItemIcon( modItem )

    if ( not IsNullOrEmpty( material ) ) then
        self.data:SetString("action_icon", material )
    else
        self.data:SetString("action_icon", "gui/hud/tools_icons/sapling" )
    end

    local blueprintName = EntityService:GetBlueprintName( modItem )
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

    if ( self.cultivatorSaplingMenu == nil or self.cultivatorSaplingMenu == INVALID_ID or not EntityService:IsAlive(self.cultivatorSaplingMenu) ) then
        self.cultivatorSaplingMenu = nil
        return
    end

    local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
    if ( menuDB == nil ) then
        return
    end
    menuDB:SetString("sapling_icon", saplingIcon)
    menuDB:SetString("sapling_name", saplingName)

    self.showPlantIcon = self.showPlantIcon or 0

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
        self:PopulateSpecialActionInfo()

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

    local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, drone_search_radius, self.predicate )

    for entity in Iter( entities ) do
        EntityService:RemoveComponent( entity, "VegetationLifecycleEnablerComponent")
    end
end

function flora_cultivator:OnItemEquippedEvent( evt )

    self.item = evt:GetItem()
    if ( EntityService:IsAlive(self.item) == false ) then
        return
    end

    local blueprintName = EntityService:GetBlueprintName( self.item )

    local slotName = evt:GetSlot()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetDatabase( self.entity )
    database:SetString(key, blueprintName)

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
        EntityService:RemoveComponent( self.entity, "FloraCultivatorComponent")
    else
        self.spawn_blueprint = nil
    end

    local plant_prefab = ""

    if db:HasString("plant_prefab") then

        plant_prefab = db:GetStringOrDefault( "plant_prefab", "" )

        self.spawn_prefab = BuildingService:CreateFloraCultivatorComponent( self.entity, plant_prefab )
    else
        EntityService:RemoveComponent( self.entity, "FloraCultivatorComponent")
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

function flora_cultivator:OnLuaGlobalEventCultivatorShowHideIcon()
    -- Legacy Empty function
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

    self.showPlantIcon = self.showPlantIcon or 0

    if ( BuildingService:IsBuildingFinished( self.entity ) ) then
        visible = self.showPlantIcon
    end

    if ( self.cultivatorSaplingMenu == nil or self.cultivatorSaplingMenu == INVALID_ID or not EntityService:IsAlive(self.cultivatorSaplingMenu) ) then
        self.cultivatorSaplingMenu = nil
        return
    end

    local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
    if ( menuDB == nil ) then
        return
    end
    menuDB:SetInt("sapling_visible", visible)
end

function flora_cultivator:OnUpdateProductionExecute()

    local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )

    if ( modItem == INVALID_ID or modItem == nil ) then

        self.data:SetString( "stat_categories", "" )
        return
    end

    local blueprintName = EntityService:GetBlueprintName( modItem )
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

    local rowNumber = 1
    local productionGroupContent = ""

    local inventoryComp = blueprint:GetComponent("InventoryItemComponent")
    if ( inventoryComp ~= nil ) then

        local inventoryCompRef = reflection_helper(inventoryComp)

        if ( inventoryCompRef ~= nil ) then

            local rowName = "row" .. tostring(rowNumber)

            productionGroupContent = rowName

            self.data:SetString("production_group.rows." .. rowName .. ".name", inventoryCompRef.name )
            self.data:SetString("production_group.rows." .. rowName .. ".icon", "gui/hud/tools_icons/sapling" )
            self.data:SetString("production_group.rows." .. rowName .. ".value", "" )

            rowNumber = rowNumber + 1
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
                "ferdonite",

                -- Tower Arsenal
                "cosmonite_ore",
                "plasmanite",

                -- Expanded Arsenal
                "voidinite_ore"
            }

            local resourceList = PlayerService:GetGlobalResourcesList()

            for i = 1, #resourceList, 1 do

                local resourceName = resourceList[i]

                if ( IndexOf( resourceNamesList, resourceName ) == nil ) then
                    Insert( resourceNamesList, resourceName )
                end
            end

            for resourceName in Iter( resourceNamesList ) do

                if ( PlayerService:IsResourceUnlocked( resourceName ) and self:IsResourceInGatherable( resourceName, gatherCompRef.resources.resource ) ) then

                    local rowName = self:AddResourceToProductionGroup(resourceName, rowNumber)

                    if ( rowName and rowName ~= nil and rowName ~= "" ) then

                        if ( string.len(productionGroupContent) > 0 ) then
                            productionGroupContent = productionGroupContent .. ","
                        end

                        productionGroupContent = productionGroupContent .. rowName

                        rowNumber = rowNumber + 1
                    end
                end
            end
        end
    end

    self.data:SetString("stat_categories", "production_group")
    self.data:SetString("production_group.rows", productionGroupContent )
end

function flora_cultivator:AddResourceToProductionGroup( resourceName, rowNumber )

    if ( not ResourceManager:ResourceExists( "GameplayResourceDef", resourceName ) ) then

        return ""
    end

    local resourceDef = ResourceManager:GetResource("GameplayResourceDef", resourceName)
    if ( resourceDef == nil ) then
        return ""
    end

    local resourceDefRef = reflection_helper( resourceDef )

    local rowName = "row" .. tostring(rowNumber)

    self.data:SetString("production_group.rows." .. rowName .. ".name", resourceDefRef.localization_id )
    self.data:SetString("production_group.rows." .. rowName .. ".icon", resourceDefRef.icon )
    self.data:SetString("production_group.rows." .. rowName .. ".value",  "" )

    return rowName
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

function flora_cultivator:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == false) then

        self:GettingInfoFromRuin()
    end
end

function flora_cultivator:GettingInfoFromRuin()

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

        self.saplingFromRuins = ""

        local modItemBlueprintName = ruinDatabase:GetStringOrDefault(selfLowName .. "_MOD_1", "") or ""

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

            local modItemBlueprintName = ""

            local modItem = ItemService:GetEquippedItem( self.entity, "MOD_1" )

            if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                modItemBlueprintName = EntityService:GetBlueprintName(modItem)
            end

            ruinDatabase:SetString(selfLowName .. "_MOD_1", modItemBlueprintName)
        else

            self.saplingFromRuins = self.saplingFromRuins or ""

            ruinDatabase:SetString(selfLowName .. "_MOD_1", self.saplingFromRuins)
        end

        ::continue::
    end
end

return flora_cultivator
