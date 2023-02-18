require ( "lua/utils/enumerables.lua" )
class 'campaign_mission_remove' ( LuaGraphNode )

function campaign_mission_remove:__init()
	LuaGraphNode.__init(self,self)
end

function campaign_mission_remove:init()
end

function campaign_mission_remove:Activated()   
	local result = self.data:GetStringOrDefault("mission_result", "win" );
	local missionName  = self.data:GetString("mission_name" );
	local missionResult = StringToMissionStatus(result);
	CampaignService:RemoveMission(missionName, missionResult );
	self:SetFinished();
end


return campaign_mission_remove