local item = require("lua/items/item.lua")

class 'barrier' ( item )

function barrier:__init()
	item.__init(self)
end

function barrier:OnEquipped()
	ItemService:AddHealthLink( self.owner, self.item )
end

function barrier:OnUnequipped()
	ItemService:RemoveHealthLink( self.owner, self.item )
end

return barrier
