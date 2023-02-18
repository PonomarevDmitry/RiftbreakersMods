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
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "")
    if ( pos.first == false ) then
        return
    end
    local tower = PlayerService:BuildBuildingAtSpot(self.bp, pos.second )
	ItemService:SetItemCreator( tower, self.entity_blueprint );

    EntityService:DissolveEntity( tower, 1.0, self.data:GetFloatOrDefault("timeout", 20.0) )
end

function  mini_miner:CanActivate()
    if ( self.owner ~= nil ) then
        local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "")
        return pos.first
    end
    return false
end

function mini_miner:OnLoad()
    item.OnLoad(self)
    self.bp = self.bp or self.data:GetStringOrDefault("blueprint", "items/consumables/mini_miner" )
end

return mini_miner