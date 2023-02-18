local item = require("lua/items/item.lua")

class 'portable_rift' ( item )

function portable_rift:__init()
	item.__init(self,self)
end

function portable_rift:OnInit()
end

function portable_rift:OnEquipped()
	--LogService:Log("Equipped")
end

function portable_rift:OnActivate()
	--LogService:Log("Activate")
	PlayerService:DropItem( self.entity, self.owner , self.owner)
	QueueEvent( "RiftPointActiveChangeRequest", self.entity, true )
end

function portable_rift:OnPickUp()
	QueueEvent( "RiftPointActiveChangeRequest", self.entity, false )
	--LogService:Log("Pick")
end

return portable_rift
