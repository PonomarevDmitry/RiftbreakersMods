class 'familiarity_level' ( LuaGraphNode )

function familiarity_level:__init()
    LuaGraphNode.__init(self,self)
end

function familiarity_level:init()
	self.familiarity_level = self.data:GetIntOrDefault( "familiarity_level", 1 )
	self.species_name = self.data:GetString( "species_name" )
	self.subspecies_name = self.data:GetStringOrDefault( "sub_species_name", "" )
end

function familiarity_level:IsReadyForResearch()
	if PlayerService.GetFamiliarityLevel then
		return PlayerService:GetFamiliarityLevel(self.species_name, self.subspecies_name ) >= self.familiarity_level;
	end

	return false
end

function familiarity_level:OnResearchAcquired()
end

return familiarity_level