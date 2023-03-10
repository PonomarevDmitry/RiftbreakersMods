local item = require("lua/items/item.lua")

class 'grenade' ( item )

function grenade:__init()
	item.__init(self,self)
end

function grenade:OnInit()
    self.bp = self.data:GetString( "bp" )
	self.att = self.data:GetString( "att" )
end

function grenade:OnEquipped()

end

function grenade:OnActivate()
	local entity = WeaponService:ThrowGrenade( self.bp , self.owner, self.att )
	ItemService:SetItemCreator( entity, self.entity_blueprint );
end

function grenade:OnDeactivate()
	return true
end


return grenade
