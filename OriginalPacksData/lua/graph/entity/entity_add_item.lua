class 'entity_add_item' ( LuaGraphNode )

function entity_add_item:__init()
    LuaGraphNode.__init(self, self)
end

function entity_add_item:init()
end

function entity_add_item:Activated()
    self.count = self.data:GetInt( "count" )
    self.item = self.data:GetString( "item" )
    self.allPlayers = self.data:GetStringOrDefault("all_players","0")
    if ( self.allPlayers == "0") then
	    local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
        for i = 1, self.count,1 do
            PlayerService:AddItemToInventory( playerId, self.item )
        end
    else
        local players =PlayerService:GetAllPlayers()
        for playerId in Iter(players) do
            for i = 1, self.count,1 do
                PlayerService:AddItemToInventory( playerId, self.item )
            end
        end
    end
    self:SetFinished()
end

return entity_add_item