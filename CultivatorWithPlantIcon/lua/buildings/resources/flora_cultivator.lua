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
        if not IsEquippedItemBlueprintValid( self.default_item, default_blueprint )  then
            self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
        end

        if self.item and self.item ~= INVALID_ID then
            if not IsEquippedItemBlueprintValid( self.item, default_blueprint ) then
                ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
            end
        end
    end

    self:CreateProductionStateMachine()

    self:RegisterBuildMenuTracker()
end

function flora_cultivator:RegisterBuildMenuTracker()

    self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEventCultivatorShowHideIcon" )
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

    local default_blueprint = self:GetDefaultSaplingItem()

    self.default_item = ItemService:GetFirstItemForBlueprint( self.entity, default_blueprint )

    if self.default_item == INVALID_ID then
        self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
    end

    if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
        ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
    end

    self:DisableVegetationAround();
end

function flora_cultivator:_OnBuildingModifiedEvent()

    if ( drone_spawner_building._OnBuildingModifiedEvent ) then
        drone_spawner_building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function flora_cultivator:OnActivate()

    if ( self.default_item ~= INVALID_ID ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
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
        self.spawn_prefab = nil
    end

    Assert( (self.spawn_blueprint or self.spawn_prefab) ~= nil, "ERROR: missing plant info! " .. db:GetStringOrDefault( "plant_prefab", "" ) .. " " .. db:GetStringOrDefault( "plant_blueprint", "" ) );

    self:DisableVegetationAround();
    self:RefreshDrones()
end

function flora_cultivator:DestoryPlanIcon()

    if ( self.cultivatorSaplingMenu == nil ) then
        return
    end

    EntityService:RemoveEntity( self.cultivatorSaplingMenu )
    self.cultivatorSaplingMenu = nil
end

function flora_cultivator:OnLuaGlobalEventCultivatorShowHideIcon( evt )

    local eventName = evt:GetEvent()

    if eventName == "CultivatorHidePlantIcon" then

        self.showPlantIcon = 0

        self:CreateMenuEntity()

        local visible = 0

        if ( BuildingService:IsBuildingFinished( self.entity ) ) then
            visible = self.showPlantIcon
        end

        local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
        menuDB:SetInt("sapling_visible", visible)

    elseif eventName == "CultivatorShowPlantIcon" then

        self.showPlantIcon = 1

        self:CreateMenuEntity()

        local visible = 0

        if ( BuildingService:IsBuildingFinished( self.entity ) ) then
            visible = self.showPlantIcon
        end

        local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
        menuDB:SetInt("sapling_visible", visible)
    end
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

return flora_cultivator
