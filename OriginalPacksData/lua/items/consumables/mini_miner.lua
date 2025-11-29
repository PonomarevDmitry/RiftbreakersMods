local item = require("lua/items/item.lua")

class 'mini_miner' ( item )

function mini_miner:__init()
	item.__init(self,self)
end

function mini_miner:OnInit()
	self.bp  = self.data:GetStringOrDefault("blueprint", "items/consumables/mini_miner" )
end

function mini_miner:OnEquipped()
end

function mini_miner:OnActivate()
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId)
   	
    if ( pos.first == false ) then
        return
    end
    local tower = PlayerService:BuildBuildingAtSpot(self.bp, pos.second, playerId )
	ItemService:SetItemCreator( tower, self.entity_blueprint );
	EntityService:PropagateEntityOwner( tower, self.owner )

    EntityService:DissolveEntity( tower, 1.0, self.data:GetFloatOrDefault("timeout", 20.0) )
end

function  mini_miner:CanActivate()
	if ( not item.CanActivate( self ) ) then
        return false
    end
    
    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
    	self:SetCanActivate( false )

        return false
    end
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId)
   	self:SetCanActivate( pos.first )
    return pos.first
end

function mini_miner:OnLoad()
    item.OnLoad(self)
    self.bp = self.bp or self.data:GetStringOrDefault("blueprint", "items/consumables/mini_miner" )
end

return mini_miner