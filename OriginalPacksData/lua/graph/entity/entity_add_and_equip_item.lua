class 'entity_add_equip_item' ( LuaGraphNode )

function entity_add_equip_item:__init()
    LuaGraphNode.__init(self, self)
end

function entity_add_equip_item:init()
end

function entity_add_equip_item:Activated()
    self.slot = self.data:GetString( "hand" )
    self.item = self.data:GetString( "item" )
    self.allPlayers = self.data:GetStringOrDefault("all_players", "0")
    if ( self.allPlayers == "0") then
    	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
        local itemEnt = PlayerService:AddItemToInventory( playerId, self.item )
        PlayerService:EquipItemInSlot( playerId, itemEnt, self.slot )
    else
        local players =PlayerService:GetAllPlayers()
        for playerId in Iter(players) do
            local itemEnt = PlayerService:AddItemToInventory( playerId, self.item )
            PlayerService:EquipItemInSlot( playerId, itemEnt, self.slot )
        end
    end

    self:SetFinished()
end

return entity_add_equip_item