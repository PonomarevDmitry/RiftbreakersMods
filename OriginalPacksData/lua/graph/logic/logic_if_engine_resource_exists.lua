class 'logic_if_resource_exists' ( LuaGraphNodeSelector )

function logic_if_resource_exists:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_resource_exists:init()
end

function logic_if_resource_exists:Activated()		
    self.wait_until_true = self.data:GetString("wait_until_true")  == "true"
    self.resource_name = self.data:GetString("resource_name")    
    self.resource_type = self.data:GetString("resource_type")    
end

function logic_if_resource_exists:Update()
	if ResourceManager:ResourceExists(self.resource_type, self.resource_name) then
		self:SetFinished( "true" )
	elseif not self.wait_until_true then
		self:SetFinished( "false" )
	end
end

return logic_if_resource_exists