class 'tower_alien_influence_spikes' ( LuaEntityObject )

function tower_alien_influence_spikes:__init()
	LuaEntityObject.__init(self,self)
end

function tower_alien_influence_spikes:init()
	self.initialPos = EntityService:GetPosition( self.entity ) 
	self.initialPos.y = EnvironmentService:GetTerrainHeight( self.initialPos )
	EntityService:SetPosition( self.entity, self.initialPos.x, self.initialPos.y, self.initialPos.z )
    local size = EntityService:GetBoundsSize( self.entity )
    self.spikeHeight = size.y;

    local hasWater = false
    local cellEnt = EnvironmentService:GetTerrainCell( self.initialPos )
	if cellEnt ~= INVALID_ID then
 		if EntityService:HasComponent( cellEnt, "WaterLayerComponent" ) then
 			EffectService:SpawnEffects( self.entity, "water" )
 			hasWater = true
 		end
	end

	if hasWater == false then 
		EffectService:SpawnEffects( self.entity, "default" )
	end

    EntityService:SetOrientation( self.entity, 0, 1, 0, RandFloat( 0.0, 360.0 ) )

	self.spikeTime = self.data:GetFloatOrDefault( "duration", 1.0 )
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { enter="OnEnter", execute="OnExecute", exit="OnExit" } )
	self.fsm:ChangeState( "working" )
end

function tower_alien_influence_spikes:OnEnter( state )
	state:SetDurationLimit( self.spikeTime )
end

function tower_alien_influence_spikes:OnExecute( state, dt )
	local duration = state:GetDuration()
	if  duration < ( self.spikeTime / 2.0 ) then
		local factor = math.cos( ( duration * math.pi ) - math.pi );
		EntityService:SetPosition( self.entity, self.initialPos.x, self.initialPos.y + ( ( 1 + ( factor * -factor ) ) * self.spikeHeight ), self.initialPos.z )
	else
		duration = duration - ( self.spikeTime / 2.0 )
		local factor = math.cos( ( duration * math.pi ) - math.pi / 2.0);
		EntityService:SetPosition( self.entity, self.initialPos.x, self.initialPos.y + self.spikeHeight - ( ( factor * factor ) * self.spikeHeight ), self.initialPos.z )
	end
end

function tower_alien_influence_spikes:OnExit( state )
	EntityService:RemoveEntity( self.entity )
end

return tower_alien_influence_spikes
 