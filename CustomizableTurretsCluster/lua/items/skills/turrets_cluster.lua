local item = require("lua/items/item.lua")

class 'turrets_cluster' ( item )

function turrets_cluster:__init()
    item.__init(self,self)
end

function turrets_cluster:OnInit()

    if ( item.OnInit ) then
        item.OnInit(self)
    end
end

function turrets_cluster:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end
end

function turrets_cluster:OnEquipped()
end

function turrets_cluster:OnActivate()

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        return
    end

    local originalPosition = {}
    originalPosition.x = pos.second.x
    originalPosition.y = pos.second.y
    originalPosition.z = pos.second.z

    local positions = self:FindPositionsToBuild(8)

    local position = nil
    local positionNumber = 1

    for i=1,3 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        LogService:Log("OnActivate modItemBlueprint " .. tostring(modItemBlueprint))

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

        if ( not blueprintDatabase:HasString("blueprint") ) then
            goto continue
        end

        position,positionNumber = self:GetPositionToBuild(originalPosition, positionNumber, positions)

        if ( position == nil ) then
            goto continue
        end

        LogService:Log("OnActivate position.x " .. tostring(position.x) .. " position.y " .. tostring(position.y) .. " position.z " .. tostring(position.z))

        local turretBlueprint = blueprintDatabase:GetString("blueprint")
        local timeout = blueprintDatabase:GetFloatOrDefault("timeout", 20.0)

        LogService:Log("OnActivate turretBlueprint " .. tostring(turretBlueprint))

        local tower = PlayerService:BuildBuildingAtSpot( turretBlueprint, position )
        ItemService:SetItemCreator( tower, self.entity_blueprint )
        EntityService:DissolveEntity( tower, 1.0, timeout )

        position.z = position.z + 2

        LogService:Log("OnActivate tower " .. tostring(tower))

        ::continue::
    end
end

function turrets_cluster:CanActivate()

    if ( item.CanActivate ) then
        item.CanActivate(self)
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        return false
    end

    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, "items/consumables/sentry_gun", "", "")
    if ( pos.first == false ) then
        return false
    end

    for i=1,3 do

        local modItemBlueprint = self.data:GetStringOrDefault("turrets_cluster_MOD_" .. tostring(i), "") or ""

        if ( modItemBlueprint ~= nil and modItemBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", modItemBlueprint ) ) then

            local blueprintDatabase = EntityService:GetBlueprintDatabase( modItemBlueprint )

            if ( blueprintDatabase and blueprintDatabase:HasString("blueprint") ) then

                return true
            end
        end
    end

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

    local result = BuildingService:IsSpaceOccupied( newPosition, "", "" )

    return result
end

function turrets_cluster:FindPositionsToBuild(cellCount)

    local result = {}

    if ( cellCount <= 0 ) then
        return result
    end

    local delta = 2

    for indexX = 0,cellCount do
        for indexZ = 0,cellCount do

            local maxIndex = math.max(indexX, indexZ)
            local totalIndex = indexX + indexZ

            local newPosition = nil

            newPosition = {}
            newPosition.x = indexX * delta
            newPosition.z = indexZ * delta

            newPosition.maxIndex = maxIndex
            newPosition.totalIndex = totalIndex

            Insert( result, newPosition )

            if ( indexZ ~= 0 ) then

                newPosition = {}
                newPosition.x = indexX * delta
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

            if ( indexX ~= 0 and indexZ ~= 0 ) then

                newPosition = {}
                newPosition.x = - indexX * delta
                newPosition.z = - indexZ * delta

                newPosition.maxIndex = maxIndex
                newPosition.totalIndex = totalIndex

                Insert( result, newPosition )
            end
        end
    end

    local sorter = function( position1, position2 )

        if (position1.maxIndex ~= position2.maxIndex) then

            return position1.maxIndex < position2.maxIndex
        end

        if (position1.totalIndex ~= position2.totalIndex) then

            return position1.totalIndex < position2.totalIndex
        end

        if (position1.x ~= position2.x) then

            return position1.x > position2.x
        end

        return position1.z > position2.z
    end

    table.sort(result, sorter)

    return result
end

return turrets_cluster