class 'weather_generic_local' ( LuaGraphNode )

function weather_generic_local:__init()
	LuaGraphNode.__init(self,self)
end

function weather_generic_local:init()
end

function weather_generic_local:Activated()

	local weatherGenericBlueprint = self.data:GetString( "weather_generic_blueprint" )
	local timeOfDayPreset = self.data:GetString( "time_of_day_preset" )
	local damagePerSecond = self.data:GetFloat( "damage_per_second" )
	local damageType = self.data:GetString( "damage_type" )
	local healthPercentage = self.data:GetFloat( "health_percentage" )
	local lifeTime = self.data:GetInt( "life_time" )
	local radius = self.data:GetInt( "radius" )
	
	local marker_color_r = self.data:GetInt( "marker_color_r" ) / 255
	local marker_color_g = self.data:GetInt( "marker_color_g" ) / 255
	local marker_color_b = self.data:GetInt( "marker_color_b" ) / 255
	local marker_color_a = self.data:GetInt( "marker_color_a" ) / 255

	local weather = AcidRainService:SpawnLocalGeneric( INVALID_ID, weatherGenericBlueprint, timeOfDayPreset, damagePerSecond, damageType, lifeTime, healthPercentage, radius )

	local position = EntityService:GetPosition( weather )
	GuiService:AddMinimapCircleMarker( position, tostring( weather ), radius, marker_color_r, marker_color_g, marker_color_b, 90 / 255 )

	self:SetFinished()

end

return weather_generic_local