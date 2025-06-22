require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

local item = require("lua/items/item.lua")

class 'turrets_cluster' ( item )

function turrets_cluster:__init()
    item.__init(self,self)
end

function turrets_cluster:GetModsConfiguration()

    local result = {}

    local hasItems = false

    for i=1,6 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continueLabel
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continueLabel
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

        if ( blueprintDatabase == nil ) then
            goto continueLabel
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continueLabel
        end

        hasItems = true

        result[i] = modItemBlueprint

        ::continueLabel::
    end

    if ( hasItems == false )  then

        result[1] = "items/turrets_cluster_mods/mobile_turret_standard_item"
    end

    return result
end

function turrets_cluster:OnActivate()

    local unlimitedMoney = ConsoleService:GetConfig("cheat_unlimited_money") == "1"
    local unlimitedAmmo = ConsoleService:GetConfig("cheat_unlimited_ammo") == "1"

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        return
    end

    local originalPosition = {}
    originalPosition.x = pos.second.x
    originalPosition.y = pos.second.y
    originalPosition.z = pos.second.z

    local positions = self:FindPositionsToBuild(20)

    local position = nil
    local positionNumber = 1

    local modsConfiguration = self:GetModsConfiguration()

    for i=1,6 do

        local modItemBlueprint = modsConfiguration[i]

        if ( modItemBlueprint == nil or modItemBlueprint == "" ) then
            goto continueSlot
        end

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then
            goto continueSlot
        end

        local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )
        if ( blueprintDatabase == nil ) then
            goto continueSlot
        end

        if ( not blueprintDatabase:HasString("blueprint_list") ) then
            goto continueSlot
        end

        local blueprintListString = blueprintDatabase:GetString("blueprint_list")

        local blueprintListArray = Split( blueprintListString, "," )

        for itemBlueprintName in Iter( blueprintListArray ) do

            local playerItem = ItemService:GetFirstItemForBlueprint( self.owner, itemBlueprintName )
            if ( playerItem == INVALID_ID ) then
                goto continueBlueprintListArray
            end

            local inventoryItemRuntimeDataComponent = EntityService:GetComponent( playerItem, "InventoryItemRuntimeDataComponent" )
            if ( inventoryItemRuntimeDataComponent == INVALID_ID ) then
                goto continueBlueprintListArray
            end

            local inventoryItemRuntimeDataComponentRef = reflection_helper(inventoryItemRuntimeDataComponent)

            if ( inventoryItemRuntimeDataComponentRef.use_count <= 0 ) then
                goto continueBlueprintListArray
            end

            local itemBlueprintDatabase = EntityService:GetBlueprintDatabase( playerItem )

            if ( itemBlueprintDatabase == nil ) then
                goto continueBlueprintListArray
            end

            if ( not itemBlueprintDatabase:HasString("blueprint") ) then
                goto continueBlueprintListArray
            end

            local turretBlueprint = itemBlueprintDatabase:GetString("blueprint")
            local timeout = itemBlueprintDatabase:GetFloatOrDefault("timeout", 20.0)

            position,positionNumber = self:GetPositionToBuild(originalPosition, positionNumber, positions)

            if ( position == nil ) then
                goto continueSlot
            end

            local tower = PlayerService:BuildBuildingAtSpot( turretBlueprint, position )
            ItemService:SetItemCreator( tower, self.entity_blueprint )
            EntityService:PropagateEntityOwner( tower, self.owner )
            EntityService:DissolveEntity( tower, 1.0, timeout )

            if ( unlimitedMoney == false and unlimitedAmmo == false ) then
                inventoryItemRuntimeDataComponentRef.use_count = inventoryItemRuntimeDataComponentRef.use_count - 1
            end

            do
                break
            end

            ::continueBlueprintListArray::
        end

        ::continueSlot::
    end
end

function turrets_cluster:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        self:SetCanActivate( false )
        return false
    end

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        self:SetCanActivate( false )
        return false
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

function turrets_cluster:GetPositionToBuild(originalPosition, positionNumber, positions)

    for i=positionNumber,#positions do

        local vector = positions[i]

        local newPosition = {}
        newPosition.y = originalPosition.y
        newPosition.x = originalPosition.x + vector.x
        newPosition.z = originalPosition.z + vector.z

        if ( not self:IsPositionOccupied(newPosition) ) then

            return newPosition,(i+1)
        end
    end

    return nil,(#positions+1)
end

function turrets_cluster:IsPositionOccupied(newPosition)

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

function turrets_cluster:FindPositionsToBuild(cellCount)

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

function turrets_cluster:AddToResult(result, indexX, indexZ)

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

return turrets_cluster