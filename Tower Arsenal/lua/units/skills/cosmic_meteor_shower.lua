local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_cosmic_meteor_shower' ( base_skill )

function skill_cosmic_meteor_shower:__init()
	base_skill.__init(self, self)
end

function skill_cosmic_meteor_shower:OnInit()
	self.meteorBp			= self.data:GetString( "meteor_blueprint" )
	self.type				= self.data:GetString( "type" )
	self.warningBp		    = self.data:GetString( "warning_bp" )
	self.spawnMinTime		= self.data:GetFloat( "spawn_min_time" )
	self.spawnMaxTime		= self.data:GetFloat( "spawn_max_time" )
	self.delayMin			= self.data:GetFloat( "delay_min" )
	self.delayMax			= self.data:GetFloat( "delay_max" )
	self.radius				= self.data:GetInt( "radius" )
	self.meteorsInOneSpawn	= self.data:GetInt( "meteors_in_one_spawn" )
	self.speed				= self.data:GetFloatOrDefault( "speed", 140 )
	self.spread				= self.data:GetFloatOrDefault( "spread", 15 )

    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { execute="OnExecuteSpawn" } )
	
	self:SetSpawnTime()
end


function skill_meteor_shower:SetSpawnTime()
	self.spawnTimer = RandFloat( self.spawnMinTime, self.spawnMaxTime )
end

function skill_meteor_shower:OnExecuteSpawn( state, dt )
	self.spawnTimer = self.spawnTimer - dt

	if ( self.spawnTimer <= 0.0 ) then
		for i = 1, self.meteorsInOneSpawn, 1 do 

			if ( self.currentTarget ~= INVALID_ID ) then
				MeteorService:SpawnMeteorInRadius( self.currentTarget, self.meteorBp, self.radius, 50, self.speed, self.spread, RandFloat( self.delayMin, self.delayMax ), self.warningBp )
			end

		end

		self:SetSpawnTime()
	end

end

function skill_meteor_shower:OnUnitAggressiveStateEvent( evt )
	self.spawner:ChangeState( "spawn" )
end

function skill_meteor_shower:OnUnitNotAggressiveStateEvent( evt )
	local state  = self.spawner:GetState( self.spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end

function skill_meteor_shower:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

return skill_cosmic_meteor_shower