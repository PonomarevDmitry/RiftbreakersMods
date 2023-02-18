local building = require("lua/buildings/building.lua")

class 'communications_hub' ( building )

function communications_hub:__init()
	building.__init(self,self)
end

function communications_hub:OnBuildingEnd()
    CampaignService:UnlockAchievement(ACHIEVEMENT_ASHLEY_PHONE_HOME)
end

return communications_hub
