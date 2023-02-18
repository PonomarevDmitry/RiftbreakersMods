local item = require("lua/items/item.lua")

class 'mobile_lamp' ( item )

function mobile_lamp:__init()
	item.__init(self,self)
end

function mobile_lamp:OnInit()
end

function mobile_lamp:OnEquipped()

	
end

function mobile_lamp:OnActivate()
	EffectService:SpawnEffect(self.entity, "items/consumables/mobile_lamp")
end

return mobile_lamp