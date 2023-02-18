class 'add_item' ( LuaGraphNode )

function add_item:__init()
    LuaGraphNode.__init(self,self)
end

function add_item:init()
	self.item = self.data:GetString("blueprint" )
	self.slot = self.data:GetStringOrDefault( "slot", "" )
end

function add_item:IsReadyForResearch()
	return true
end

function add_item:OnResearchAcquired()
    local itemEnt = PlayerService:AddItemToInventory( 0, self.item )
    PlayerService:EquipItemInSlot( 0, itemEnt, self.slot )
end

return add_item