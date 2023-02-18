class 'entity_add_item' ( LuaGraphNode )

function entity_add_item:__init()
    LuaGraphNode.__init(self, self)
end

function entity_add_item:init()
end

function entity_add_item:Activated()
    self.count = self.data:GetInt( "count" )
    self.item = self.data:GetString( "item" )
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
    LogService:Log("Add item to player: " .. tostring(playerId))
    self.mech = PlayerService:GetPlayerControlledEnt(playerId)
    for i = 1, self.count,1 do
        ItemService:AddItemToInventory( self.mech, self.item )
    end
    self:SetFinished()
end

return entity_add_item