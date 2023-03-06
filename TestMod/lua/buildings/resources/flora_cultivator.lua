require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'flora_cultivator' ( drone_spawner_building )

local DEFAULT_SAPLING_BLUEPRINT = "items/loot/saplings/biomas_sapling_item";

function flora_cultivator:__init()
    drone_spawner_building.__init(self,self)
end

function flora_cultivator:OnInit()
    drone_spawner_building.OnInit( self )

    self.default_item = INVALID_ID

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )

    self.showPlantIcon = 1

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "update_production", { execute="OnUpdateProductionExecute", interval=1.0 } )
    self.fsm:ChangeState("update_production")

    self:registerBuildMenuTracker()
end

function flora_cultivator:registerBuildMenuTracker()

    self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEventTest" )
end

function flora_cultivator:CreateMenuEntity()

    self:registerBuildMenuTracker()

    if ( self.cultivatorSaplingMenuSpot == nil ) then
        self.cultivatorSaplingMenuSpot = EntityService:SpawnAndAttachEntity(self.entity, "att_landing" )
    end

    if ( self.cultivatorSaplingMenu == nil ) then

        self.cultivatorSaplingMenu = EntityService:SpawnAndAttachEntity("misc/cultivator_sapling_menu", self.cultivatorSaplingMenuSpot)

        local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )

        if ( self.showPlantIcon == nil ) then
            self.showPlantIcon = 1
        end

        menuDB:SetInt("sapling_visible", self.showPlantIcon)
    end
end

function flora_cultivator:OnRelease()

    if ( self.cultivatorSaplingMenu ~= nil and self.cultivatorSaplingMenu ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.cultivatorSaplingMenu )
    end

    if ( self.cultivatorSaplingMenuSpot ~= nil and self.cultivatorSaplingMenuSpot ~= INVALID_ID ) then
        EntityService:RemoveEntity( self.cultivatorSaplingMenuSpot )
    end
    
    drone_spawner_building.OnRelease( self )
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
    drone_spawner_building.OnLoad(self)

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

function flora_cultivator:OnBuildingEnd()

    self:CreateMenuEntity()

    local default_blueprint = self:GetDefaultSaplingItem()

    self.default_item = ItemService:GetFirstItemForBlueprint( self.entity, default_blueprint )

    if self.default_item == INVALID_ID then
        self.default_item = ItemService:AddItemToInventory( self.entity, default_blueprint )
    end

    if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
        ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
    end

    self:DisableVegetationAround();

    drone_spawner_building.OnBuildingEnd(self)
end

function flora_cultivator:OnActivate()
    if ( self.default_item ~= INVALID_ID ) then
        if not ItemService:IsSameSubTypeEquipped( self.entity, self.default_item ) then
            ItemService:EquipItemInSlot( self.entity, self.default_item, "MOD_1" )
        end
    end

    drone_spawner_building.OnActivate(self)
    self:RefreshDrones()
end

function flora_cultivator:PopulateSpecialActionInfo()

    if ( self.item ~= INVALID_ID and self.item ~= nil ) then
        local material = ItemService:GetItemIcon( self.item )

        local blueprintName = EntityService:GetBlueprintName( self.item )
        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local saplingIcon = componentRef.icon
        local saplingName = componentRef.name
        
        self.data:SetString("action_icon", material )

        self:CreateMenuEntity()

        local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
        menuDB:SetString("sapling_icon", saplingIcon)
        menuDB:SetString("sapling_name", saplingName)
    end

    self:OnUpdateProductionExecute()

    local plant_blueprint = self.data:GetStringOrDefault("plant_blueprint", "")
    
    if plant_blueprint == "" then
        plant_blueprint = self.data:GetStringOrDefault("plant_prefab", "")
    end

    if plant_blueprint == "" then
        return
    end

    self.data:SetString("stat_categories", "gui/hud/build_menu/info.plants" )
    self.data:SetString("gui/hud/build_menu/info.plants.icon", "")
    self.data:SetString("gui/hud/build_menu/info.plants.rows", "plant" )
    self.data:SetString("gui/hud/build_menu/info.plants.rows.plant.name", plant_blueprint )
    
    if ( self.item ~= INVALID_ID and self.item ~= nil ) then
        local material = ItemService:GetItemIcon( self.item )
        
        self.data:SetString("gui/hud/build_menu/info.plants.rows.plant.icon", material )
        self.data:SetString("gui/hud/build_menu/info.plants.rows.plant.value",  "" )
    end
end

function flora_cultivator:RefreshDrones()
    for drone in Iter(self.drones) do
        self:DroneSpawned(drone)
    end
    
    self:PopulateSpecialActionInfo()
end

function flora_cultivator:DroneSpawned(drone)
    drone_spawner_building.DroneSpawned( self, drone )

    local db = EntityService:GetDatabase( drone )
    if db ~= nil then
        db:SetString( "plant_blueprint", self.spawn_blueprint or "" )
        db:SetString( "plant_prefab", self.spawn_prefab or "" )
        db:SetString( "cultivate_target", self.cultivate_target or "" )
    end
end

function flora_cultivator:OnLuaGlobalEventTest( evt )

    local eventName = evt:GetEvent()
    
    if eventName == "CultivatorHidePlantIcon" then

        self.showPlantIcon = 0

        if ( self.cultivatorSaplingMenu ~= nil ) then
            local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
            menuDB:SetInt("sapling_visible", 0)
        end
    elseif eventName == "CultivatorShowPlantIcon" then

        self.showPlantIcon = 1

        if ( self.cultivatorSaplingMenu ~= nil ) then
            local menuDB = EntityService:GetDatabase( self.cultivatorSaplingMenu )
            menuDB:SetInt("sapling_visible", 1)
        end
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

    local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, drone_search_radius, {
        signature = "VegetationLifecycleEnablerComponent"
    } );

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

function flora_cultivator:OnUpdateProductionExecute()

    if ( self.item ~= INVALID_ID and self.item ~= nil ) then
        local material = ItemService:GetItemIcon( self.item )

        local blueprintName = EntityService:GetBlueprintName( self.item )
        local blueprint = ResourceManager:GetBlueprint( blueprintName )

        local component = blueprint:GetComponent("InventoryItemComponent")

        local componentRef = reflection_helper(component)

        local saplingName = componentRef.name
        
        self.data:SetString("stat_categories", "production_group" )

        self.data:SetString("production_group.rows", "plant" )

        self.data:SetString("production_group.rows.plant.name", saplingName )
        self.data:SetString("production_group.rows.plant.icon", "gui/hud/tools_icons/sapling" )
        self.data:SetString("production_group.rows.plant.value",  "" )
    else
        self.data:SetString("stat_categories", "" )
    end
end

return flora_cultivator
