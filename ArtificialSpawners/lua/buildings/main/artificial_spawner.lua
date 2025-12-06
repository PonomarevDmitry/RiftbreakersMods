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

    self:RegisterEventHandlers()

    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end

    self.timeoutTime = nil
end

function artificial_spawner:OnLoad()

    if ( building.OnLoad ) then
        building.OnLoad(self)
    end

    self:RegisterEventHandlers()

    if ( is_server and is_client ) then
        self:CreateMenuEntity()
    end

    self.timeoutTime = nil
end

function artificial_spawner:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ItemEquippedEvent", "OnItemEquippedEvent" )
    self:RegisterHandler( self.entity, "ItemUnequippedEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipedItemEvent", "OnItemUnequippedEvent" )
    self:RegisterHandler( self.entity, "UnequipItemRequest", "OnItemUnequippedEvent" )

    self:UnregisterHandlers( "EnterBuildMenuEvent" )
    self:UnregisterHandlers( "EnterFighterModeEvent" )
end

function artificial_spawner:OnInteractWithEntityRequest( event )

    --local player = PlayerService:GetPlayerByMech( event:GetOwner() )

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    self:SpawnWaves()
end

function artificial_spawner:SpawnWaveLogicFiles( waveLogic, waveLogicMul, spawnDistance, ignoreWater )

    if ( ResourceManager:ResourceExists( "FlowGraphTemplate", waveLogic ) ) then

        --LogService:Log( "artificial_spawner:OnHarvestStartEvent - exist : " .. tostring( waveLogic ) )

        local spawnPoint = UnitService:CreateDynamicSpawnPoints( self.entity, spawnDistance, waveLogicMul, ignoreWater )

        for i = 1, #spawnPoint do

            local point = spawnPoint[i]

            if ( point ~= INVALID_ID ) then

                self.data:SetString( "spawn_point", EntityService:GetName( point ) )
                MissionService:ActivateMissionFlow( "", waveLogic, "default", self.data )

                local pathCleaner = EntityService:SpawnEntity( "misc/path_cleaner", self.entity, "" )

                local db = EntityService:GetOrCreateDatabase( pathCleaner )
                db:SetString( "to_entity", tostring( point ) )
                db:SetString( "from_entity", tostring( self.entity ) )

            else
                LogService:Log( "artificial_spawner:OnHarvestStartEvent - could not create a spawn point." )
            end
        end

        return true

    elseif ( waveLogic ~= "error" ) then
        LogService:Log( "artificial_spawner:OnHarvestStartEvent - file does not exist : " .. waveLogic )
    end

    return false
end

function artificial_spawner:SpawnWaves()

    local cooldown = 5

    self.timeoutTime = GetLogicTime() + cooldown

    local aggressiveRadius = self.data:GetFloatOrDefault( "aggressive_radius", 20 )
    local waveEffect = self.data:GetStringOrDefault( "wave_started_effect", "" ) or ""

    local blueprints = self:GetWavesTemplatesArray()

    for blueprintName in Iter(blueprints) do

        local blueprintDatabase = EntityService:GetBlueprintDatabase( blueprintName )

        local waveLogic			= blueprintDatabase:GetStringOrDefault( "wave_logic_file", "error" )
        local bossLogic			= blueprintDatabase:GetStringOrDefault( "boss_logic_file",  "error" )
        local waveLogicMul		= blueprintDatabase:GetIntOrDefault( "wave_logic_file_mul", 1 )
        local bossLogicMul		= blueprintDatabase:GetIntOrDefault( "boss_logic_file_mul",  0 )
        local waterOverride		= blueprintDatabase:GetIntOrDefault( "water_override", 0 )
        local waveSpawnDistance = blueprintDatabase:GetIntOrDefault( "wave_spawn_distance", 40 )

        local ignoreWater = false

        if ( waterOverride == 1 ) then
            ignoreWater = true
        end

        if ( blueprintDatabase:HasFloat("aggressive_radius") ) then

            local waveAggressiveRadius = blueprintDatabase:GetFloatOrDefault( "aggressive_radius", 20 )

            aggressiveRadius = math.max(aggressiveRadius, waveAggressiveRadius)
        end

        if ( waveEffect == "" and blueprintDatabase:HasString("wave_started_effect") ) then

            waveEffect = blueprintDatabase:GetString( "wave_started_effect" ) or ""
        end

        self:SpawnWaveLogicFiles( waveLogic, waveLogicMul, waveSpawnDistance, ignoreWater )
        self:SpawnWaveLogicFiles( bossLogic, bossLogicMul, waveSpawnDistance, ignoreWater )
    end

    local delay = self.data:GetFloatOrDefault( "delay", 0 )


    if ( waveEffect ~= "" ) then
        EffectService:SpawnEffect(self.entity, waveEffect);
    end

    EntityService:SpawnEntity( "items/consumables/radar_pulse", self.entity, "" )

    if ( delay > 0) then
        local entity = EntityService:SpawnEntity( "props/special/loot_containers/loot_container_delayer", self.entity, "")
        local db = EntityService:GetOrCreateDatabase( entity )
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

    local database = EntityService:GetOrCreateDatabase( self.entity )
    database:SetString(key, itemBlueprintName)
end

function artificial_spawner:OnItemUnequippedEvent( evt )

    local slotName = evt:GetSlot()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)
    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local key = selfLowName .. "_" .. slotName

    local database = EntityService:GetOrCreateDatabase( self.entity )
    database:SetString(key, "")
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

                local blueprintDatabase = EntityService:GetBlueprintDatabase( modItem ) or EntityService:GetOrCreateDatabase( modItem )

                if ( blueprintDatabase and blueprintDatabase:HasString("spawner_blueprint") ) then

                    local blueprintName = blueprintDatabase:GetString("spawner_blueprint")

                    Insert(result, blueprintName)
                end
            end
        end
    end

    if ( #result == 0 ) then

        local defaultBiomeBlueprint = self:GetDefaultBiomeBlueprint()

        local blueprintDatabase = EntityService:GetBlueprintDatabase( defaultBiomeBlueprint )

        if ( blueprintDatabase and blueprintDatabase:HasString("spawner_blueprint") ) then

            local blueprintName = blueprintDatabase:GetString("spawner_blueprint")

            Insert(result, blueprintName)
        end
    end

    return result
end

function artificial_spawner:GetDefaultBiomeBlueprint()

    local biomeName = MissionService:GetCurrentBiomeName()

    local result = "items/artificial_spawner_waves/" .. biomeName .. "_standard"

    return result
end

function artificial_spawner:OnBuildingEnd()

    if ( building.OnBuildingEnd ) then
        building.OnBuildingEnd(self)
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
end

function artificial_spawner:OnEnterBuildMenuEvent( evt )
end

function artificial_spawner:OnEnterFighterModeEvent( evt )
end

function artificial_spawner:CreateMenuEntity()

    local menuBlueprintName = "misc/artificial_spawner_slots_menu"

    local menuEntity = nil

    local children = EntityService:GetChildren( self.entity, true )
    for child in Iter(children) do

        local blueprintName = EntityService:GetBlueprintName( child )
        if ( blueprintName == menuBlueprintName and EntityService:GetParent( child ) == self.entity ) then

            menuEntity = child

            break
        end
    end

    if ( menuEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        menuEntity = EntityService:SpawnAndAttachEntity(menuBlueprintName, self.entity, team)
    end

    if ( menuEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == menuBlueprintName and child ~= menuEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    if ( menuEntity == nil or menuEntity == INVALID_ID or not EntityService:IsAlive( menuEntity ) ) then
        return
    end

    if ( not EntityService:HasComponent( menuEntity, "LuaComponent" ) ) then

        QueueEvent( "RecreateComponentFromBlueprintRequest", menuEntity, "LuaComponent" )
    end

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    EntityService:SetPosition( menuEntity, 0, sizeSelf.y + 3, 0 )

    local menuDB = EntityService:GetOrCreateDatabase( menuEntity )
    if ( menuDB ) then
        menuDB:SetInt("menu_visible", 0)
    end
end

function artificial_spawner:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == false) then

        self:GettingInfoFromRuin()
    end
end

function artificial_spawner:GettingInfoFromRuin()

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

                    local slotItemsFromRuinsBlueprintName = ""

                    if ( modItemBlueprintName ~= nil and modItemBlueprintName ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprintName ) ) then
                        slotItemsFromRuinsBlueprintName = modItemBlueprintName
                    end

                    self.slotItemsFromRuins[databaseParameter] = slotItemsFromRuinsBlueprintName
                end
            end
        end

        ::continue::
    end
end

function artificial_spawner:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

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

        local equipmentComponent = EntityService:GetComponent(self.entity, "EquipmentComponent")
        if ( equipmentComponent ~= nil ) then

            local equipment = reflection_helper( equipmentComponent ).equipment[1]

            local slots = equipment.slots
            for i=1,slots.count do

                local slot = slots[i]

                local databaseParameterBlueprintName = ""

                local modItem = ItemService:GetEquippedItem( self.entity, slot.name )
                if ( modItem ~= nil and modItem ~= INVALID_ID ) then
                    databaseParameterBlueprintName = EntityService:GetBlueprintName( modItem )
                end

                local databaseParameter = selfLowName .. "_" .. slot.name

                ruinDatabase:SetString(databaseParameter, databaseParameterBlueprintName)
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

return artificial_spawner
