local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_shockwave' ( base_skill )

function skill_shockwave:__init()
	base_skill.__init(self, self)
end

function skill_shockwave:OnInit()
	self.shockwaveBp		= self.data:GetString( "shockwave_blueprint" )
	self.spawnTime			= self.data:GetFloat( "spawn_time" )
	self.auraEffect			= self.data:GetString( "aura_effect" )

    self.spawner = self:CreateStateMachine()
    self.spawner:AddState( "spawn", { execute="OnExecuteSpawn" } )
	
	self.spawnTimer = self.spawnTime;

	EffectService:AttachEffects( EntityService:GetParent( self.entity ), self.auraEffect )
end

function skill_shockwave:OnExecuteSpawn( state, dt )
	self.spawnTimer = self.spawnTimer - dt

	if ( ( self.spawnTimer <= 0.0 ) and ( self.currentTarget ~= INVALID_ID ) ) then
		
		local rock = EntityService:SpawnEntity( self.shockwaveBp, self.entity, "" )
		EntityService:SetTeam( rock, EntityService:GetTeam( self.entity ) )
		self.spawnTimer = self.spawnTime;
	end

end

function skill_shockwave:OnUnitAggressiveStateEvent( evt )
	self.spawner:ChangeState( "spawn" )
end

function skill_shockwave:OnUnitNotAggressiveStateEvent( evt )
	local state  = self.spawner:GetState( self.spawner:GetCurrentState() )
	if( state ~= nil ) then
		state:Exit()
	end
end

function skill_shockwave:OnUnitDeadStateEvent( evt )
	EffectService:DestroyEffectsByGroup( EntityService:GetParent( self.entity ), self.auraEffect )
	EntityService:RemoveEntity( self.entity )
end

return skill_shockwave