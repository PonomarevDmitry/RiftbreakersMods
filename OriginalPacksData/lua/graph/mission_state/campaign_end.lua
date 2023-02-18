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
	self.showCredits = self.data:GetIntOrDefault("show_credits", 1)
	local action = StringToCampaignStatus(self.action);
    CampaignService:EndGame( self.outro, action, self.nextMission, self.showCredits == 1 );
	self:SetFinished();
end


return campaign_end