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
    for i = 1, self.count,1 do
        PlayerService:AddItemToInventory( playerId, self.item )
    end
    self:SetFinished()
end

return entity_add_item