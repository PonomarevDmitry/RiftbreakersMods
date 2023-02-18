class 'logic_and' ( LuaGraphNode )

function logic_and:__init()
    LuaGraphNode.__init(self, self)
end

function logic_and:init()    
end

function logic_and:Activated()
    self:SetFinished()
end

return logic_and