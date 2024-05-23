class 'campaign_end' ( LuaGraphNode )
require ( "lua/utils/enumerables.lua" )

function campaign_end:__init()
	LuaGraphNode.__init(self,self)
end

function campaign_end:init()

end

function campaign_end:Activated()   
	self.outro = self.data:GetString("outro")
	self.action = self.data:GetString("action")
	self.nextMission = self.data:GetStringOrDefault("next_mission", "")
	self.result = self.data:GetStringOrDefault("mission_result", "win")
	self.showCredits = self.data:GetIntOrDefault("show_credits", 1)
	local action = StringToCampaignStatus(self.action);
	local missionResult = StringToMissionStatus(self.result);
	LogService:Log("campaign_end:Activated() status: " .. self.result .. " missionResult: " .. tostring(missionResult));
    CampaignService:EndGame( self.outro, action, self.nextMission, self.showCredits == 1, missionResult);
	self:SetFinished();
end


return campaign_end