class 'logic_disable_node' ( LuaGraphNode )

function logic_disable_node:__init()
    LuaGraphNode.__init(self, self)
end

function logic_disable_node:init()
end

function logic_disable_node:Activated()
    local name = self.data:GetString("name");
    self.parent:DisableNode(name)
    self:SetFinished()
end

return logic_disable_node