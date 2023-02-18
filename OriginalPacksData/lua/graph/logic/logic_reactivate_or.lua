class 'logic_reactivate_or' ( LuaGraphNode )

function logic_reactivate_or:__init()
    LuaGraphNode.__init(self, self)
end

function logic_reactivate_or:init()
end

function logic_reactivate_or:Activated()
    local name = self.data:GetString("name");
    self.parent:ReactivateOrNode(name)
    self:SetFinished()
end

return logic_reactivate_or