local item = require("lua/items/item.lua")

class 'skin' ( item )

function skin:__init()
	item.__init(self,self)
end

function skin:OnInit()
	self.material = self.data:GetString("material")
end

function skin:OnEquipped()
	if ( EntityService:IsAlive( self.owner) ) then
		EntityService:ChangeMaterial( self.owner, self.material )
	end
end

function skin:OnActivate()
end

return skin
