require("lua/utils/reflection.lua")
require("lua/utils/numeric_utils.lua")

local item = require("lua/items/item.lua")

class 'mini_miner' ( item )

function mini_miner:__init()
    item.__init(self,self)
end

function mini_miner:OnInit()
    self.bp = self.data:GetStringOrDefault("blueprint", "items/consumables/mini_miner" )
end

function mini_miner:OnEquipped()
end

function mini_miner:OnActivate()
    local playerId = PlayerService:GetPlayerForEntity(self.owner)
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId )
    
    if ( pos.first == false ) then
        return
    end

    local pointToSpawn = pos.second

    if ( string.find(self.bp, "mini_miner" ) ~= nil ) then
        pointToSpawn = self:GetPointToSpawnForMiniMiner(pos.second)
    end

    local tower = PlayerService:BuildBuildingAtSpot( self.bp, pointToSpawn, playerId )
    ItemService:SetItemCreator( tower, self.entity_blueprint )
    EntityService:PropagateEntityOwner( tower, self.owner )

    EntityService:DissolveEntity( tower, 1.0, self.data:GetFloatOrDefault("timeout", 20.0) )
end

function mini_miner:GetPointToSpawnForMiniMiner(originalPosition)

    local resourceVolume = self:GetResourceVolume(originalPosition)
    if ( resourceVolume == nil ) then
        return originalPosition
    end

    local resourceVolumeComponent = EntityService:GetComponent( resourceVolume, "ResourceVolumeComponent" )
    if ( resourceVolumeComponent == nil ) then
        return originalPosition
    end

    local resourceVolumeComponentRef = reflection_helper( resourceVolumeComponent )

    local childrenList = self:GetResourceChilds(resourceVolume)
    if ( #childrenList > 0 ) then

        for childResource in Iter( childrenList ) do

            local position = EntityService:GetPosition(childResource)

            if ( not FindService:IsGridMarkedWithLayer(position, "OwnerLayerComponent") ) then

                return position
            end
        end
    end

    return originalPosition
end

function mini_miner:GetResourceVolume(originalPosition)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, 0.75)

    local min = VectorSub(originalPosition, scaleVector)
    local max = VectorAdd(originalPosition, scaleVector)

    local predicate = {

        signature = "ResourceComponent",

        filter = function(entity)

            local positionTemp = EntityService:GetPosition( entity )

            if ( not ( min.x <= positionTemp.x and positionTemp.x <= max.x ) ) then
                return false
            end

            if ( not ( min.z <= positionTemp.z and positionTemp.z <= max.z ) ) then
                return false
            end

            return true
        end
    }

    local tempCollection = FindService:FindEntitiesByPredicateInBox( min, max, predicate )

    if ( #tempCollection > 0 ) then

        local resourceEntity = tempCollection[1]

        local resourceComponent = EntityService:GetComponent( resourceEntity, "ResourceComponent" )
        if ( resourceComponent ~= nil ) then

            local resourceComponentRef = reflection_helper( resourceComponent )

            if ( resourceComponentRef.volume_owner ~= nil and resourceComponentRef.volume_owner.id ~= nil ) then

                return resourceComponentRef.volume_owner.id
            end
        end
    end

    return nil
end

function mini_miner:GetResourceChilds(resourceVolume)

    local childrenList = EntityService:GetChildren( resourceVolume, false )

    local result = {}

    local resourceValueHash = {}
    local distancesHash = {}

    for childResource in Iter( childrenList ) do

        if ( IndexOf( result, childResource ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( childResource, "ResourceComponent" ) ) then
            goto continue
        end

        local resourceValue = EntityService:GetResourceAmount( childResource )
        if ( resourceValue.second <= 0 ) then
            goto continue
        end

        resourceValueHash[childResource] = resourceValue.second

        distancesHash[childResource] = EntityService:GetDistanceBetween( childResource, self.owner )

        Insert( result, childResource )

        ::continue::
    end

    local sorter = function( lh, rh )
        
        if (resourceValueHash[lh] ~= resourceValueHash[rh]) then

            return resourceValueHash[lh] > resourceValueHash[rh]
        end

        return distancesHash[lh] < distancesHash[rh]
    end

    table.sort(result, sorter)

    return result
end

function mini_miner:CanActivate()
    if ( not item.CanActivate( self ) ) then
        self:SetCanActivate( false )
        return false
    end

    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
        self:SetCanActivate( false )

        return false
    end
    
    local playerId = PlayerService:GetPlayerForEntity(self.owner)
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId )

    self:SetCanActivate( pos.first )
    return pos.first
end

function mini_miner:OnLoad()
    item.OnLoad(self)
    self.bp = self.bp or self.data:GetStringOrDefault("blueprint", "items/consumables/mini_miner" )
end

return mini_miner