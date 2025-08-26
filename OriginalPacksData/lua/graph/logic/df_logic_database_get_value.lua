class 'df_logic_database_get_value' ( LuaGraphNode )

function df_logic_database_get_value:__init()
    LuaGraphNode.__init(self, self)
end

function df_logic_database_get_value:init()    
end

function df_logic_database_get_value:Activated()
	local key = self.data:GetString("key")
	local type = self.data:GetString("type")
	
	local bindings = self.parent:GetDatabase()
	if type == "int" then
		self.data:SetInteger( "out_value", bindings:GetInteger(key ))
	elseif type == "string" then
		self.data:SetString( "out_value", bindings:GetString(key ))
	elseif type == "float" then
		self.data:SetFloat( "out_value", bindings:GetFloat(key ))
	end

    self:SetFinished()
end

return df_logic_database_get_value