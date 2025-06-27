class 'logic_if_campaign_type' ( LuaGraphNodeSelector )

function logic_if_campaign_type:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_campaign_type:init()	
end

function logic_if_campaign_type:Activated()
	self.campaignType = self.data:GetString("campaign_type")	
	
	if self.campaignType == CampaignService:GetCurrentCampaignType() then
		self:SetFinished("true")
	else
		self:SetFinished("false")
	end	
end

return logic_if_campaign_type