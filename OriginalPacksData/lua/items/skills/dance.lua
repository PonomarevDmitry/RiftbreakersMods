local item = require("lua/items/item.lua")

class 'dance' ( item )

function dance:__init()
	item.__init(self,self)
end

function dance:OnInit()
end

function dance:OnEquipped()

	
end

function dance:OnActivate()
	AnimationService:StartAnim( self.owner, "melee", false ) 
end


return dance
