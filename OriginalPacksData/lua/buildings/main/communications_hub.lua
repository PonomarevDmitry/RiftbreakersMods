local building = require("lua/buildings/building.lua")

class 'communications_hub' ( building )

function communications_hub:__init()
	building.__init(self,self)
end

function communications_hub:OnInit()	
	self.communicationsVersion = 1
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
end
function communications_hub:OnBuildingEnd()
    CampaignService:UnlockAchievement(ACHIEVEMENT_ASHLEY_PHONE_HOME)
end

function communications_hub:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
    QueueEvent("OpenResearchRequest", player )
end

function communications_hub:OnLoad()
    building.OnLoad(self)
    if ( self.communicationsVersion == nil or self.communicationsVersion < 1 ) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
		self.communicationsVersion = 1
	end
end

return communications_hub
