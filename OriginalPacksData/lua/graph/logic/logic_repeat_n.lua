class 'logic_repeat_n' ( LuaGraphNodeSelector )

function logic_repeat_n:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_repeat_n:init()	
    self.counter = self.data:GetInt("counter")
    self.currentCounter = 0
end

function logic_repeat_n:Activated()
	if self.currentCounter >= self.counter then
		self:SetFinished("false")
	else
		self:SetFinished("true")
	end
    self.currentCounter = self.currentCounter + 1
end

return logic_repeat_n