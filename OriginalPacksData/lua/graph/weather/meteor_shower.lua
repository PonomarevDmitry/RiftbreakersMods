class 'meteor_shower' ( LuaGraphNode )

function meteor_shower:__init()
	LuaGraphNode.__init(self,self)
end

function meteor_shower:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit= "OnExitWait" } )
end

function meteor_shower:Activated()

	local blueprint			= self.data:GetString( "blueprint" )
	local type				= self.data:GetStringOrDefault( "type", "in_place" )
	local warningBp		    = self.data:GetStringOrDefault( "warning_bp", "" )
	local duration			= self.data:GetInt( "duration" )
	local durationMax		= self.data:GetIntOrDefault( "duration_max", 90 )
	local spawnTime			= self.data:GetFloat( "spawn_time" )
	local delay				= self.data:GetFloatOrDefault( "delay", 0.0 )
	local radius			= self.data:GetInt( "radius" )
	local meteorsInOneSpawn	= self.data:GetInt( "meteors_in_one_spawn" )

	self.timer = math.random( duration, durationMax )

	MeteorService:SpawnMeteorShower( CameraService:GetActiveCamera(), blueprint, self.timer, spawnTime, radius, meteorsInOneSpawn, delay, warningBp, type )

	self.fsm:ChangeState( "wait" )
end

function meteor_shower:OnEnterWait( state )
    state:SetDurationLimit( self.timer )
end

function meteor_shower:OnExitWait( state )
    self:SetFinished()
end

return meteor_shower