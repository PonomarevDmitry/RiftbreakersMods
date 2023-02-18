class 'acid_rain_spawn_global' ( LuaGraphNode )

function acid_rain_spawn_global:__init()
	LuaGraphNode.__init(self,self)
end

function acid_rain_spawn_global:init()
end

function acid_rain_spawn_global:Activated()
	local acidRainBlueprint = self.data:GetString( "acid_rain_blueprint" )
	local timeOfDayPreset = self.data:GetString( "time_of_day_preset" )
	local damagePerSecond = self.data:GetFloat( "damage_per_second" )
	local healthpercentage = self.data:GetFloatOrDefault( "health_percentage", 33.0 )
	local lifeTime = self.data:GetInt( "life_time" )

	AcidRainService:SpawnAcidRain( acidRainBlueprint, timeOfDayPreset, damagePerSecond, lifeTime, healthpercentage )

	self:SetFinished()

end

return acid_rain_spawn_global