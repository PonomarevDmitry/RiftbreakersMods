class 'logic_set_console_var' ( LuaGraphNode )

function logic_set_console_var:__init()
    LuaGraphNode.__init(self, self)
end

function logic_set_console_var:init()	
end

function logic_set_console_var:Activated()
	self.consoleVar = self.data:GetString("console_var")
	self.consoleValue = self.data:GetString("value")	
	
	ConsoleService:ExecuteCommand( self.consoleVar .. " " .. self.consoleValue )
	self:SetFinished()
end

return logic_set_console_var