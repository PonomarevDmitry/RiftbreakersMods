class 'logic_switch_on_value' ( LuaGraphNodeSelector )

function logic_switch_on_value:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_switch_on_value:init()
end

function logic_switch_on_value:Activated()	

	local currentValue = self.data:GetString("value")

	self:SetFinished( currentValue )
	
end

return logic_switch_on_value