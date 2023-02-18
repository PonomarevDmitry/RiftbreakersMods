local item = require("lua/items/item.lua")

class 'potion' ( item )

function potion:__init()
	item.__init(self,self)
end

function potion:OnInit()
    self.amount   = self.data:GetFloat( "amount" )
end

function potion:OnEquipped()

	
end

function potion:OnActivate()
	HealthService:AddHealthInPercentage( self.owner, self.amount )
	EffectService:SpawnEffect(self.entity, "effects/items/potion")
end

return potion
