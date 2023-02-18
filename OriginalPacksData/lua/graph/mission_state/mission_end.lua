require ( "lua/utils/enumerables.lua" )
class 'mission_end' ( LuaGraphNode )

function mission_end:__init()
	LuaGraphNode.__init(self,self)
end

function mission_end:init()

end

function mission_end:Activated()   
	local result = self.data:GetStringOrDefault("mission_result", "win" );
	local missionResult = StringToMissionStatus(result);
	MissionService:FinishCurrentMission( missionResult );

	self:SetFinished();
end


return mission_end