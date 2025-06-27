local item = require("lua/items/item.lua")

class 'sentry_gun' ( item )

function sentry_gun:__init()
	item.__init(self,self)
end

function sentry_gun:OnInit()
	self.bp  = self.data:GetStringOrDefault("blueprint", "items/consumables/sentry_gun" )
end

function sentry_gun:OnEquipped()
end

function sentry_gun:OnActivate()
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId)
   	
    if ( pos.first == false ) then
        return
    end
    local tower = PlayerService:BuildBuildingAtSpot(self.bp, pos.second , playerId)
	ItemService:SetItemCreator( tower, self.entity_blueprint );
	EntityService:PropagateEntityOwner( tower, self.owner )

    EntityService:DissolveEntity( tower, 1.0, self.data:GetFloatOrDefault("timeout", 20.0) )
end

function  sentry_gun:CanActivate()
	item.CanActivate( self )
    if ( self.owner == nil or EntityService:IsAlive( self.owner ) == false ) then
   	    self:SetCanActivate( false )
       return false
    end
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
    local pos = FindService:FindEmptySpotForBuildingRadius( self.owner, 6.0, self.bp, "", "", playerId)
   	self:SetCanActivate( pos.first )
    return pos.first
end

function sentry_gun:OnLoad()
    item.OnLoad(self)
    self.bp = self.bp or self.data:GetStringOrDefault("blueprint", "items/consumables/sentry_gun" )
end

return sentry_gun