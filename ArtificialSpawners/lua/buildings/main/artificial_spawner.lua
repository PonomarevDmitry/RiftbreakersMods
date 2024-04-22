require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")

local building = require("lua/buildings/building.lua")

class 'artificial_spawner' ( building )

function artificial_spawner:__init()
    building.__init(self,self)
end

function artificial_spawner:OnInit()

    ItemService:SetInvisible(self.entity, true)

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    local owner = self.data:GetIntOrDefault( "owner", 0 )

    if ( PlayerService:IsInFighterMode( owner ) ) then
        self.showMenu = 0
    else
        self.showMenu = 1
    end

    self:PopulateSpecialActionInfo()

    self.timeoutTime = nil
end

function artificial_spawner:OnLoad()

    if ( building.OnLoad ) then
        building.OnLoad(self)
    end

    self:RegisterEventHandlers()

    self:CreateMenuEntity()

    self.showMenu = self.showMenu or 0

    self:PopulateSpecialActionInfo()

    self.timeoutTime = nil
end

function artificial_spawner:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )

    self:RegisterHandler( event_sink, "EnterBuildMenuEvent", "OnEnterBuildMenuEvent" )
    self:RegisterHandler( event_sink, "EnterFighterModeEvent", "OnEnterFighterModeEvent" )
end

function artificial_spawner:OnInteractWithEntityRequest( event )

    --local player = PlayerService:GetPlayerByMech( event:GetOwner() )

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    self:SpawnWaves()
end

function artificial_spawner:SpawnWaves()

    self.timeoutTime = GetLogicTime() + 5

    local aggressiveRadius = self.data:GetFloatOrDefault( "aggressive_radius", 20 )

    local blueprints = self:GetWavesTemplatesArray()

    for blueprintName in Iter(blueprints) do

        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )

        local waveLogic			= blueprintDatabase:GetStringOrDefault( "wave_logic_file", "error" )
        local waveLogicMul		= blueprintDatabase:GetIntOrDefault( "wave_logic_file_mul", 1 )
        local waveSpawnDistance = blueprintDatabase:GetIntOrDefault( "wave_spawn_distance", 40 )

        if ( blueprintDatabase:HasFloat("aggressive_radius") ) then

            local waveAggressiveRadius = blueprintDatabase:GetFloatOrDefault( "aggressive_radius", 20 )

            aggressiveRadius = math.max(aggressiveRadius, waveAggressiveRadius)
        end

        if ( ResourceManager:ResourceExists( "FlowGraphTemplate", waveLogic ) ) then

            local spawnPointArray = UnitService:CreateDynamicSpawnPoints( self.entity, waveSpawnDistance, waveLogicMul )

            for i = 1, #spawnPointArray do

                local point = spawnPointArray[i]

                if ( point ~= INVALID_ID ) then

                    self.data:SetString( "spawn_point", EntityService:GetName( point ) )

                    MissionService:ActivateMissionFlow( "", waveLogic, "default", self.data )

                    local pathCleaner = EntityService:SpawnEntity( "misc/path_cleaner", self.entity, "" )

                    local db = EntityService:GetDatabase( pathCleaner )			
                    db:SetString( "to_entity", tostring( point ) )
                    db:SetString( "from_entity", tostring( self.entity ) )

                else
                    LogService:Log( "artificial_spawner:OnHarvestStartEvent - could not create a spawn point." )
                end
            end
        else
            LogService:Log( "artificial_spawner:OnHarvestStartEvent - file does not exist : " .. tostring( waveLogic ) )
        end
    end
    
    local delay = self.data:GetFloatOrDefault( "delay", 0 )

    local waveEffect = self.data:GetStringOrDefault( "wave_started_effect", "" )
    if ( waveEffect ~= "" ) then
        EffectService:SpawnEffect(self.entity, waveEffect);
    end

    if ( delay > 0) then
        local entity = EntityService:SpawnEntity( "props/special/loot_containers/loot_container_delayer", self.entity, "")
        local db = EntityService:GetDatabase( entity )
        db:SetFloat( "delay", delay )
        db:SetFloat( "aggressive_radius", aggressiveRadius )
    end
end

function artificial_spawner:OnItemEquippedEvent( evt )

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

function artificial_spawner:OnItemUnequippedEvent( evt )

    local slotName = evt:GetSlot()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetDatabase( self.entity )
    database:SetString(key, "")

    self:PopulateSpecialActionInfo()
end

function artificial_spawner:GetWavesTemplatesArray()

    local result = {}

    local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
    if ( equipmentComponent ) then

        local equipment = reflection_helper( equipmentComponent ).equipment[1]

        local slots = equipment.slots
        for i=1,slots.count do

            local slot = slots[i]

            local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
            if ( modItem ~= nil and modItem ~= INVALID_ID ) then

                local blueprintName = EntityService:GetBlueprintName(modItem)

                Insert(result, blueprintName)
            end
        end
    end

    if ( #result == 0 ) then

        local defaultBiomeBlueprint = self:GetDefaultBiomeBlueprint();

        Insert(result, defaultBiomeBlueprint)
    end

    return result
end

function artificial_spawner:GetDefaultBiomeBlueprint()

    local biomeName = MissionService:GetCurrentBiomeName()

    local result = "items/artificial_spawner_waves/" .. biomeName .. "_standard"

    return result
end

function artificial_spawner:_OnBuildingModifiedEvent()

    if ( building._OnBuildingModifiedEvent ) then
        building._OnBuildingModifiedEvent(self)
    end

    self:PopulateSpecialActionInfo()
end

function artificial_spawner:OnBuildingStart()

    if ( building.OnBuildingStart ) then
        building.OnBuildingStart(self)
    end

    self:PopulateSpecialActionInfo()
end

function artificial_spawner:OnBuildingEnd()

    if ( building.OnBuildingEnd ) then
        building.OnBuildingEnd(self)
    end

    self:PopulateSpecialActionInfo()
end

function artificial_spawner:OnEnterBuildMenuEvent( evt )

    self.showMenu = 1

    self:SetMenuVisible(self.menuEntity)
end

function artificial_spawner:OnEnterFighterModeEvent( evt )

    self.showMenu = 0

    self:SetMenuVisible(self.menuEntity)
end

function artificial_spawner:SetMenuVisible(menuEntity)

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

function artificial_spawner:CreateMenuEntity()

    local menuBlueprintName = "misc/artificial_spawner_slots_menu"

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
    EntityService:SetPosition( self.menuEntity, 0, sizeSelf.y + 3, 0 )

    local menuDB = EntityService:GetDatabase( self.menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function artificial_spawner:PopulateSpecialActionInfo()

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

    menuDB:SetInt("slot_rarity_1", 0)
    menuDB:SetInt("slot_rarity_2", 0)
    menuDB:SetInt("slot_rarity_3", 0)

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

        local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
        if ( modItem ~= nil and modItem ~= INVALID_ID ) then

            local blueprintName = EntityService:GetBlueprintName( modItem )

            local blueprint = ResourceManager:GetBlueprint( blueprintName )
            if ( blueprint ~= nil ) then

                local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
                if ( inventoryItemComponent ~= nil ) then

                    local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                    menuDB:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                    menuDB:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                    menuDB:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)
                    menuDB:SetInt("slot_rarity_" .. tostring(slotsCount), inventoryItemComponentRef.rarity)

                    slotsCount = slotsCount + 1
                end
            end
        end
    end

    if ( slotsCount == 1 ) then

        local defaultBiomeBlueprint = self:GetDefaultBiomeBlueprint();

        local blueprint = ResourceManager:GetBlueprint( defaultBiomeBlueprint )
        if ( blueprint ~= nil ) then

            local inventoryItemComponent = blueprint:GetComponent("InventoryItemComponent")
            if ( inventoryItemComponent ~= nil ) then

                local inventoryItemComponentRef = reflection_helper(inventoryItemComponent)

                menuDB:SetInt("slot_visible_" .. tostring(slotsCount), 1)
                menuDB:SetString("slot_icon_" .. tostring(slotsCount), inventoryItemComponentRef.icon)
                menuDB:SetString("slot_name_" .. tostring(slotsCount), inventoryItemComponentRef.name)
                menuDB:SetInt("slot_rarity_" .. tostring(slotsCount), inventoryItemComponentRef.rarity)

                slotsCount = slotsCount + 1
            end
        end
    end

    self:SetMenuVisible(menuEntity)
end

return artificial_spawner
