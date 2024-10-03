class 'tornado_spawn' ( LuaGraphNode )

function tornado_spawn:__init()
    LuaGraphNode.__init(self,self)
end

function tornado_spawn:init()
end

function tornado_spawn:Activated()

	local tornadoBlueprint = self.data:GetString( "tornado_blueprint" )
	local type = self.data:GetString( "type" )
	local spawnPlace = self.data:GetString( "spawn_place" )
	local count = self.data:GetInt( "count" )
	local outsideRadiusDistance = self.data:GetInt( "outside_radius_distance" )

	local minLifeTime = 20
	local maxLifeTime = 30

	if ( self.data:HasInt( "min_life_time" ) ) then 
		minLifeTime = self.data:GetInt( "min_life_time" )
	end

	if ( self.data:HasInt( "max_life_time" ) ) then 
		maxLifeTime = self.data:GetInt( "max_life_time" )
	end

	TornadoService:SpawnTornado( tornadoBlueprint, type, spawnPlace, count, outsideRadiusDistance, minLifeTime, maxLifeTime )

	self:SetFinished()

end

return tornado_spawn