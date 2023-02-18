local item = require("lua/items/item.lua")

class 'dash' ( item )

function dash:__init()
	item.__init(self,self)
end

function dash:OnInit()
end

function dash:OnEquipped()
end

function dash:OnActivate()
	EntityService:Dash( self.owner, self.item);
end

return dash
