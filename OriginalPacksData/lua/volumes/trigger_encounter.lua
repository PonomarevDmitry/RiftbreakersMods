class 'trigger_encounter' ( LuaEntityObject )

function trigger_encounter:__init()
	LuaEntityObject.__init(self, self)
end

function trigger_encounter:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" )
	self.missionScript = self.data:GetString( "logic_path" )
end

function trigger_encounter:OnEnteredTriggerEvent( evt )
	if not MissionService:IsGraphActive( self.missionScript ) then
		MissionService:ActivateMissionFlow( self.missionScript, self.missionScript )
		local tileName = MissionService:GetTileNameForPosition( self.entity )
		if tileName then
			local campaignData = CampaignService:GetCampaignData()
			local encounterCount = campaignData:GetIntOrDefault( tileName, 0 )
			campaignData:SetInt( tileName, encounterCount + 1 )
		end
		
	end
	EntityService:RemoveEntity( self.entity )
end

return trigger_encounter