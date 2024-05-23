class 'acid_fissures' ( LuaGraphNode )

function acid_fissures:__init()
	LuaGraphNode.__init(self,self)
end

function acid_fissures:init()
end

function acid_fissures:Activated()

	local acidFissuresBp = self.data:GetString( "acid_fissures_bp" )
	local timeOfDayPreset = self.data:GetString( "time_of_day_preset" )
	local markerBp = self.data:GetString( "marker_bp" )
	local damagePerSecond = self.data:GetFloat( "damage_per_second" )
	local healthPercentage = self.data:GetFloat( "health_percentage" )
	local localEffectsRandomOffset = self.data:GetFloat( "local_effects_random_offset" )
	local minimumDistancePerLocalEffect = self.data:GetFloat( "minimum_distance_per_local_effect" )
	local lifeTime = self.data:GetInt( "life_time" )
	local radius = self.data:GetFloat( "radius" )

	local marker_color_r = self.data:GetInt( "marker_color_r" ) / 255
	local marker_color_g = self.data:GetInt( "marker_color_g" ) / 255
	local marker_color_b = self.data:GetInt( "marker_color_b" ) / 255
	local marker_color_a = self.data:GetInt( "marker_color_a" ) / 255

	local acidFissures = AcidRainService:SpawnAcidFissures( acidFissuresBp, timeOfDayPreset, markerBp, damagePerSecond, lifeTime, healthPercentage, radius, localEffectsRandomOffset, minimumDistancePerLocalEffect )

	local position = EntityService:GetPosition( acidFissures )
	GuiService:AddMinimapCircleMarker( position, tostring( acidFissures ), radius, marker_color_r, marker_color_g, marker_color_b, 90 / 255 )

	self:SetFinished()

end

return acid_fissures