class 'mission_change_all_permission_buildings' ( LuaGraphNode )

function mission_change_all_permission_buildings:__init()
	LuaGraphNode.__init(self,self)
end


function mission_change_all_permission_buildings:init()		
end

function mission_change_all_permission_buildings:Activated()							
	self.inputStatus = self.data:GetString("enabled")	
	
	LogService:Log( "All buildings: " .. self.inputStatus )
	if ( self.inputStatus == "true") then
		PlayerService:EnableAllBuildings()
	else
		PlayerService:DisableAllBuildings()
	end	
	self:SetFinished()	
end

return mission_change_all_permission_buildings