class 'logic_set_local_variable' ( LuaGraphNode )
require("lua/utils/table_utils.lua")

function logic_set_local_variable:__init()
    LuaGraphNode.__init(self, self)
end

function logic_set_local_variable:init()	
end

function logic_set_local_variable:Activated()

    local stringKeys = self.data:GetStringKeys()
    for key in Iter(stringKeys) do
        local uniqueVariable = self.parent:CreateGraphUniqueString( key )
        self.parent:GetDatabase():SetString( uniqueVariable, self.data:GetString( key ) )
    end

    local floatKeys = self.data:GetFloatKeys()
    for key in Iter(floatKeys) do
        local uniqueVariable = self.parent:CreateGraphUniqueString( key )
        self.parent:GetDatabase():SetFloat( uniqueVariable, self.data:GetFloat( key ) )
    end

	self:SetFinished()
end

return logic_set_local_variable