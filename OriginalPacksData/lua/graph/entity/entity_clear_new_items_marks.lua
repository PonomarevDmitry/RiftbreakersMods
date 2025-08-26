class 'entity_clear_new_items_marks' ( LuaGraphNode )

function entity_clear_new_items_marks:__init()
    LuaGraphNode.__init(self, self)
end

function entity_clear_new_items_marks:init()
end

function entity_clear_new_items_marks:Activated()
    self.mech = PlayerService:GetPlayerControlledEnt(0) --#TODO: fix player id
    ItemService:ClearNewItemsMarks( self.mech )
    self:SetFinished()
end

return entity_clear_new_items_marks