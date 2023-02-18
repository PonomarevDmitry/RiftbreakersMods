class 'entity_add_equip_item' ( LuaGraphNode )

function entity_add_equip_item:__init()
    LuaGraphNode.__init(self, self)
end

function entity_add_equip_item:init()
end

function entity_add_equip_item:Activated()
    self.slot = self.data:GetString( "hand" )
    self.item = self.data:GetString( "item" )
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
    LogService:Log("Add item and equip to player: " .. tostring(playerId))
    self.mech = PlayerService:GetPlayerControlledEnt(playerId)
    local itemEnt = ItemService:AddItemToInventory( self.mech, self.item )
    ItemService:EquipItemInSlot( self.mech, itemEnt, self.slot )

    self:SetFinished()
end

return entity_add_equip_item