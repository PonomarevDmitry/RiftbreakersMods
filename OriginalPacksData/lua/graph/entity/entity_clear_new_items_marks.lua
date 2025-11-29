class 'entity_clear_new_items_marks' ( LuaGraphNode )

function entity_clear_new_items_marks:__init()
    LuaGraphNode.__init(self, self)
end

function entity_clear_new_items_marks:init()
end

function entity_clear_new_items_marks:Activated()
    local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
    self.mech = PlayerService:GetPlayerControlledEnt(playerId) 
    ItemService:ClearNewItemsMarks( self.mech )
    self:SetFinished()
end

return entity_clear_new_items_marks