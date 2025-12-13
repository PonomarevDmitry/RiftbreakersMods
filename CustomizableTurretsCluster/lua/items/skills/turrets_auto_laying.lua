require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

local item = require("lua/items/item.lua")

class 'turrets_auto_laying' ( item )

function turrets_auto_laying:__init()
    item.__init(self,self)
end

function turrets_auto_laying:OnInit()

    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function turrets_auto_laying:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
    
    self:InitThrowStateMachine()

    self.isWorking = self.isWorking or false
end

function turrets_auto_laying:InitThrowStateMachine()

    if ( self.machine == nil ) then
        self.machine = self:CreateStateMachine()
        self.machine:AddState( "placeturret", { execute="OnPlaceTurretExecute", interval=1 } )
        self.machine:AddState( "delay", { execute="OnDelayExecute", interval=0.4 } )
    end
end

function turrets_auto_laying:OnActivate()

    self:InitThrowStateMachine()

    if ( self.isWorking ) then

        self:StopWorking()
    else

        self.isWorking = true

        self:OnPlaceTurretExecute()

        self.machine:ChangeState("delay")

        if ( self.skillWorking ~= nil ) then
            EntityService:RemoveEntity( self.skillWorking )
            self.skillWorking = nil
        end

        self.skillWorking = EntityService:SpawnAndAttachEntity( "effects/items/mech_mine_beacon_gravity_armed", self.owner, "att_grenade", EntityService:GetTeam( self.owner ) )

        ItemService:SetItemCreator( self.skillWorking, "effects/items/mech_mine_beacon_gravity_armed" )
        EntityService:PropagateEntityOwner( self.skillWorking, self.owner )

        ItemService:SetItemReference( self.skillWorking, self.entity, EntityService:GetBlueprintName( self.entity ))
    end
end

function turrets_auto_laying:OnUnequipped()

    self.lastSpawnedPosition = nil

    if ( self.isWorking ) then
        self:StopWorking()
    end
end

function turrets_auto_laying:StopWorking()

    self.lastSpawnedPosition = nil

    self.isWorking = false

    self.data:SetInt("turrets_auto_laying_current_number", 1)

    self.machine:Deactivate()

    if ( self.skillWorking ~= nil ) then

        EntityService:RemoveEntity( self.skillWorking )
        self.skillWorking = nil
    end
end

function turrets_auto_laying:OnRelease()

    if ( self.isWorking ) then
        self:StopWorking()
    end

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

function turrets_auto_laying:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        self:SetCanActivate( false )
        return false
    end

    if ( self.isWorking ) then
        self:SetCanActivate( true )
        return true
    end

    local modsConfiguration = self:GetModsConfiguration()

    for i=1,6 do

        local modItemBlueprint = modsConfiguration[i]

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continue
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continue
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

        if ( blueprintDatabase == nil ) then
            goto continue
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continue
        end

        local blueprintListString = blueprintDatabase:GetString("blueprint_list")

        local blueprintListArray = Split( blueprintListString, "," )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem ~= INVALID_ID ) then

                local inventoryItemRuntimeDataComponentRef = reflection_helper(EntityService:GetComponent( playerItem, "InventoryItemRuntimeDataComponent" ))

                if ( inventoryItemRuntimeDataComponentRef.use_count > 0 ) then

                    self:SetCanActivate( true )
                    return true
                end
            end
        end

        ::continue::
    end

    self:SetCanActivate( false )
    return false
end

function turrets_auto_laying:GetModsConfiguration()

    local result = {}

    local hasItems = false

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continue
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continue
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

        if ( blueprintDatabase == nil ) then
            goto continue
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continue
        end

        hasItems = true

        result[i] = modItemBlueprint

        ::continue::
    end

    if ( hasItems == false )  then

        result[1] = "items/turrets_cluster_mods/mobile_turret_standard_item"
    end

    return result
end

function turrets_auto_laying:OnDelayExecute( state )

    local minDistanceBetweenLast = 5

    if ( self.lastSpawnedPosition ~= nil ) then

        local spot = EntityService:GetPosition( self.owner )
        spot.y = EnvironmentService:GetTerrainHeight(spot)

        local distance = Distance(self.lastSpawnedPosition, spot)

        if ( distance < minDistanceBetweenLast ) then
            return
        end
    end

    self.machine:ChangeState("placeturret")
end

function turrets_auto_laying:OnPlaceTurretExecute( state )

    local minDistanceBetweenLast = 5

    if ( self.lastSpawnedPosition ~= nil ) then

        local spot = EntityService:GetPosition( self.owner )
        spot.y = EnvironmentService:GetTerrainHeight(spot)

        local distance = Distance(self.lastSpawnedPosition, spot)

        if ( distance < minDistanceBetweenLast ) then

            self.machine:ChangeState("delay")

            return
        end
    end

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    local playerId = PlayerService:GetPlayerForEntity(self.owner)

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "", playerId )
    if ( pos.first == false ) then
        return
    end

    local originalPosition = {}
    originalPosition.x = pos.second.x
    originalPosition.y = pos.second.y
    originalPosition.z = pos.second.z

    local currentModNumber = self.data:GetIntOrDefault("turrets_auto_laying_current_number", 1) or 1

    local emptySlots = 0

    local modsConfiguration = self:GetModsConfiguration()

    local positions = self:FindPositionsToBuild(20)

    while (true) do

        if ( emptySlots >= 6 ) then

            self.data:SetInt("turrets_auto_laying_current_number", 1)
            return
        end

        local modItemBlueprint = modsConfiguration[currentModNumber]

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )
        if ( blueprintDatabase == nil ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            emptySlots = emptySlots + 1
            currentModNumber = self:IncreaseModNumber(currentModNumber)
            goto continueModList
        end

        local blueprintListString = blueprintDatabase:GetString("blueprint_list")

        local blueprintListArray = Split( blueprintListString, "," )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem == INVALID_ID ) then
                goto continueBlueprintList
            end

            local inventoryItemRuntimeDataComponent = EntityService:GetComponent( playerItem, "InventoryItemRuntimeDataComponent" )
            if ( inventoryItemRuntimeDataComponent == INVALID_ID ) then
                goto continueBlueprintList
            end

            local inventoryItemRuntimeDataComponentRef = reflection_helper(inventoryItemRuntimeDataComponent)
            if ( inventoryItemRuntimeDataComponentRef.use_count <= 0 ) then
                goto continueBlueprintList
            end

            local itemBlueprintDatabase = EntityService:GetBlueprintDatabase( playerItem )

            if ( itemBlueprintDatabase == nil ) then
                goto continueBlueprintList
            end

            if ( not itemBlueprintDatabase:HasString("blueprint") ) then
                goto continueBlueprintList
            end

            local turretBlueprint = itemBlueprintDatabase:GetString("blueprint")
            local timeout = itemBlueprintDatabase:GetFloatOrDefault("timeout", 20.0)

            local position = self:GetPositionToBuild(originalPosition, positions)

            if ( position == nil ) then
                return
            end

            local tower = PlayerService:BuildBuildingAtSpot( turretBlueprint, position, playerId )
            ItemService:SetItemCreator( tower, self.entity_blueprint )
            EntityService:PropagateEntityOwner( tower, self.owner )
            EntityService:DissolveEntity( tower, 1.0, timeout )

            self.lastSpawnedPosition = EntityService:GetPosition( tower )

            if ( unlimitedMoney == false and unlimitedAmmo == false ) then
                inventoryItemRuntimeDataComponentRef.use_count = inventoryItemRuntimeDataComponentRef.use_count - 1
            end

            self.data:SetInt("turrets_auto_laying_current_number", self:IncreaseModNumber(currentModNumber))

            do
                return
            end

            ::continueBlueprintList::
        end

        emptySlots = emptySlots + 1
        currentModNumber = self:IncreaseModNumber(currentModNumber)

        ::continueModList::
    end
end

function turrets_auto_laying:GetPositionToBuild(originalPosition, positions)

    for i=1,#positions do

        local vector = positions[i]

        local newPosition = {}
        newPosition.y = originalPosition.y
        newPosition.x = originalPosition.x + vector.x
        newPosition.z = originalPosition.z + vector.z

        if ( not self:IsPositionOccupied(newPosition) ) then

            return newPosition
        end
    end

    return nil
end

function turrets_auto_laying:IsPositionOccupied(newPosition)

    local isSpaceOccupied = BuildingService:IsSpaceOccupied( newPosition, "", "" )
    if ( isSpaceOccupied ) then

        return true
    end

    local terrainCellEntityId = EnvironmentService:GetTerrainCell(newPosition)

    local buildingBlockerLayerComponent = EntityService:GetComponent( terrainCellEntityId, "BuildingBlockerLayerComponent" )
    if ( buildingBlockerLayerComponent ~= nil ) then
        return true
    end

    local worldBlockerLayerComponent = EntityService:GetComponent( terrainCellEntityId, "WorldBlockerLayerComponent" )
    if ( worldBlockerLayerComponent ~= nil ) then
        return true
    end

    return false
end

function turrets_auto_laying:IncreaseModNumber(currentModNumber)

    local result = currentModNumber + 1

    if ( result > 6 ) then
        result = 1
    end

    return result
end

function turrets_auto_laying:FindPositionsToBuild(cellCount)

    local result = {}

    if ( cellCount <= 0 ) then
        return result
    end

    for indexZ = 0,cellCount do
        for indexX = 0,indexZ do

            self:AddToResult(result, indexX, indexZ)

            if ( indexX ~= indexZ ) then

                self:AddToResult(result, indexZ, indexX)
            end
        end
    end

    --local sorter = function( position1, position2 )
    --
    --    if (position1.maxIndex ~= position2.maxIndex) then
    --
    --        return position1.maxIndex < position2.maxIndex
    --    end
    --
    --    if (position1.totalIndex ~= position2.totalIndex) then
    --
    --        return position1.totalIndex < position2.totalIndex
    --    end
    --
    --    if (position1.x ~= position2.x) then
    --
    --        return position1.x > position2.x
    --    end
    --
    --    return position1.z > position2.z
    --end
    --
    --table.sort(result, sorter)

    return result
end

function turrets_auto_laying:AddToResult(result, indexX, indexZ)

    local delta = 4

    local maxIndex = math.max(indexX, indexZ)
    local totalIndex = indexX + indexZ

    local newPosition = nil

    newPosition = {}
    newPosition.x = indexX * delta
    newPosition.z = indexZ * delta

    newPosition.maxIndex = maxIndex
    newPosition.totalIndex = totalIndex

    Insert( result, newPosition )

    if ( indexX ~= 0 and indexZ ~= 0 ) then

        newPosition = {}
        newPosition.x = - indexX * delta
        newPosition.z = - indexZ * delta

        newPosition.maxIndex = maxIndex
        newPosition.totalIndex = totalIndex

        Insert( result, newPosition )
    end

    if ( indexX ~= 0 ) then

        newPosition = {}
        newPosition.x = - indexX * delta
        newPosition.z = indexZ * delta

        newPosition.maxIndex = maxIndex
        newPosition.totalIndex = totalIndex

        Insert( result, newPosition )
    end

    if ( indexZ ~= 0 ) then

        newPosition = {}
        newPosition.x = indexX * delta
        newPosition.z = - indexZ * delta

        newPosition.maxIndex = maxIndex
        newPosition.totalIndex = totalIndex

        Insert( result, newPosition )
    end
end

return turrets_auto_laying