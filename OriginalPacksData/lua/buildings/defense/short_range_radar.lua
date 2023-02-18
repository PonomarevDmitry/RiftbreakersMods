local building = require("lua/buildings/building.lua")

class 'short_range_radar' ( building )

function short_range_radar:__init()
	building.__init(self,self)
end

function short_range_radar:OnInit()

end

function short_range_radar:OnActivate()
	local range = self.data:GetFloat("range")
	BuildingService:CreateRadarComponent( self.entity, range );

	if EnvironmentService:GetRadarCoveragePercentage() >= 0.75 then
		CampaignService:UnlockAchievement( ACHIEVEMENT_ALL_SEEING_EYE )
	end
end

function short_range_radar:OnDeactivate()
	EntityService:RemoveComponent( self.entity, "RadarComponent" )
	EffectService:DestroyEffectsByGroup(self.entity, "working")	
end


function short_range_radar:OnRemove()
	QueueEvent( "RemoveRadarRangeRequest", event_sink, self.entity )
end

return short_range_radar
