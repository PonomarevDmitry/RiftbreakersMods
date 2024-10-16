class 'earthquake' ( LuaGraphNode )

function earthquake:__init()
	LuaGraphNode.__init(self,self)
end

function earthquake:init()
end

function earthquake:Activated()

	local earthquakeBp = self.data:GetString( "earthquake_bp" )
	local timeOfDayPreset = self.data:GetString( "time_of_day_preset" )
	local markerBp = self.data:GetString( "marker_bp" )
	local damagePerSecond = self.data:GetFloat( "damage_per_second" )
	local healthPercentage = self.data:GetFloat( "health_percentage" )
	local localEffectsRandomOffset = self.data:GetFloat( "local_effects_random_offset" )
	local localEffectsDissolve = self.data:GetFloatOrDefault( "local_effects_dissolve", 0.0 )
	local localEffectsCooldown = self.data:GetFloatOrDefault( "local_effects_cooldown", 0.0 )
	local localEffectsInfinite = self.data:GetIntOrDefault( "local_effects_infinite", 0 )
	local minimumDistancePerLocalEffect = self.data:GetFloat( "minimum_distance_per_local_effect" )
	local lifeTime = self.data:GetInt( "life_time" )
	local cameraShakePower = self.data:GetFloat( "camera_shake_power" )
	local radius = self.data:GetFloat( "radius" )
	local cameraShakeFreq = self.data:GetInt( "camera_shake_freq" )
	
	local marker_color_r = self.data:GetInt( "marker_color_r" ) / 255
	local marker_color_g = self.data:GetInt( "marker_color_g" ) / 255
	local marker_color_b = self.data:GetInt( "marker_color_b" ) / 255
	local marker_color_a = self.data:GetInt( "marker_color_a" ) / 255

	local earthquake = EarthquakeService:SpawnEarthquake( INVALID_ID, earthquakeBp, timeOfDayPreset, markerBp, damagePerSecond, lifeTime, healthPercentage, radius, localEffectsRandomOffset, minimumDistancePerLocalEffect, cameraShakePower, cameraShakeFreq )

	local position = EntityService:GetPosition( earthquake )
	GuiService:AddMinimapCircleMarker( position, tostring( earthquake ), radius, marker_color_r, marker_color_g, marker_color_b, 90 / 255 )

	local worldEffectComponent = reflection_helper( EntityService:GetComponent( earthquake, "WorldEffectComponent") )
	worldEffectComponent.local_effects_dissolve = localEffectsDissolve
	worldEffectComponent.local_effects_cooldown = localEffectsCooldown
	worldEffectComponent.local_effects_infinite = localEffectsInfinite

	self:SetFinished()

end

return earthquake