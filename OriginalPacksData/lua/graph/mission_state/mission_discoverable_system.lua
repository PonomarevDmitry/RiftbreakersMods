require ( "lua/utils/enumerables.lua" )
class 'mission_discoverable_system' ( LuaGraphNode )

function mission_discoverable_system:__init()
	LuaGraphNode.__init(self,self)
end

function mission_discoverable_system:init()

end

function mission_discoverable_system:Activated()   
	local state = self.data:GetStringOrDefault("state", "Enable" )	
	if state == "Enable" then
		BuildingService:EnableDiscoverableSystem( true )
	else
		BuildingService:EnableDiscoverableSystem( false )
	end
	self:SetFinished();
end


return mission_discoverable_system