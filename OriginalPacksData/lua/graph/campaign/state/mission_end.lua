require ( "lua/utils/enumerables.lua" )
class 'campaign_mission_end' ( LuaGraphNode )

function campaign_mission_end:__init()
	LuaGraphNode.__init(self,self)
end

function campaign_mission_end:init()
end

function campaign_mission_end:Activated()   
	local result = self.data:GetStringOrDefault("mission_result", "win" );
	local missionName  = self.data:GetString("mission_name" );
	local missionResult = StringToMissionStatus(result);
	CampaignService:FinishMission(missionName, missionResult );
	self:SetFinished();
end


return campaign_mission_end