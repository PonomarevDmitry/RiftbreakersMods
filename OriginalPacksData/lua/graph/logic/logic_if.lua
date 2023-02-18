class 'logic_if' ( LuaGraphNodeSelector )

function logic_if:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if:init()	
end

function logic_if:Activated()
	self.consoleVar = self.data:GetString("value1")
	self.consoleValue = self.data:GetString("value2")	
	
	if self.consoleVar == self.consoleValue then
		self:SetFinished("true")
	else
		self:SetFinished("false")
	end	
end

return logic_if