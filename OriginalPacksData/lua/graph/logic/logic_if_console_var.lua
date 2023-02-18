class 'logic_if_console_var' ( LuaGraphNodeSelector )

function logic_if_console_var:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_console_var:init()	
end

function logic_if_console_var:Activated()
	self.consoleVar = self.data:GetString("console_var")
	self.consoleValue = self.data:GetString("value")	
	
	if ConsoleService:GetConfig( self.consoleVar ) == self.consoleValue then
		self:SetFinished("true")
	else
		self:SetFinished("false")
	end	
end

return logic_if_console_var