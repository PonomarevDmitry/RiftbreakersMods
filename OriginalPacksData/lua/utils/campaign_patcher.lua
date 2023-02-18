function PatchJungleFindRareResources( self )
	if ( CampaignService:GetCurrentMissionId() ~= "jungle_find_rare_resource" ) then
		return
	end
	-- Very bad
	local objectiveName = ObjectiveService:GetObjectiveUniqueNameFromObjectiveId( self.objective_id )
	if ( string.match(objectiveName, "grow_trees.connect_water") and self.data:GetString("search_target_value") == "resource_marker" ) then
		self.data:SetString( "search_target_value", "logic/position_rare_resource_deposit")
	end
end
