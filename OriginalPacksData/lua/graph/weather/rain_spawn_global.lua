class 'rain_spawn_global' ( LuaGraphNode )

function rain_spawn_global:__init()
	LuaGraphNode.__init(self,self)
end

function rain_spawn_global:init()
end

function rain_spawn_global:Activated()
	local acidRainBlueprint = self.data:GetString( "acid_rain_blueprint" )
	local timeOfDayPreset = self.data:GetString( "time_of_day_preset" )
	local lifeTime = self.data:GetInt( "life_time" )

	AcidRainService:SpawnAcidRain( acidRainBlueprint, timeOfDayPreset, 0, lifeTime, 0 )

	self:SetFinished()

end

return rain_spawn_global