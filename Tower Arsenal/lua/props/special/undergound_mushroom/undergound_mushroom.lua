 class 'acid_undergound_mushroom' ( LuaEntityObject )

function acid_undergound_mushroom:__init()
	LuaEntityObject.__init(self,self)
end

function acid_undergound_mushroom:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "InteractWithEntityRequest", 	 "OnInteractWithEntityRequest" )
	self.bp = self.data:GetString( "bp" )
	self.delay = self.data:GetFloatOrDefault( "delay", 0 )
	self.delayBeforeArmoed = self.data:GetFloatOrDefault( "delay_before_armed", 1 )
	self.explode_height = self.data:GetFloatOrDefault( "explode_height", 1.2 )
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "explode", { enter="OnExplodeStart", execute="OnExplodeExecute", exit="OnExplodeEnd" } )
	self.sm:AddState( "armed", { enter="OnArmedStart", exit="OnArmedEnd" } )
	self.exploded = false
	self.armed = false
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.0 )
	self.sm:ChangeState("armed")
end

function acid_undergound_mushroom:OnEnteredTriggerEvent( evt )
	if self.exploded == true or self.armed == false then 
		return
	end
	EntityService:RemoveLifeTime( self.entity ) 
	self.sm:ChangeState("explode")
	EffectService:DestroyEffectsByGroup( self.entity, "mine_unarmed" )
	self.exploded = true
end

function acid_undergound_mushroom:OnInteractWithEntityRequest( evt )
	self.armed = false;
	QueueEvent( "LuaGlobalEvent", event_sink, "UndergroundMushroomDetection", self.data )
end


function acid_undergound_mushroom:OnArmedStart( state )
	state:SetDurationLimit( self.delayBeforeArmoed )
end

function acid_undergound_mushroom:OnArmedEnd( state )
	self.armed = true
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 1.0 )
end

function acid_undergound_mushroom:OnExplodeStart( state )
	self.meshBp = self.data:GetStringOrDefault("mesh_bp","");
	if ( self.meshBp ~= "" ) then
		self.mesh = EntityService:SpawnAndAttachEntity(self.meshBp, self.entity )
	else
		self.mesh = self.entity
	end
	EffectService:AttachEffects( self.mesh, "mine_armed" )
	state:SetDurationLimit( self.delay )
end

function acid_undergound_mushroom:OnExplodeExecute( state )
	local progres = 0
	if ( state:GetDurationLimit() ~= 0 ) then
		progres = state:GetDuration() / state:GetDurationLimit()
	end
	EntityService:SetGraphicsUniform( self.mesh, "cGlowFactor", progres * 4 )
	--EntityService:SetScale( self.mesh, 1 + progres, 1 + progres, 1 + progres )
	EntityService:SetScale( self.mesh, 1, 1, 1 )
end

function acid_undergound_mushroom:OnExplodeEnd(  )

	QueueEvent( "LuaGlobalEvent", event_sink, "UndergroundMushroomExplosion", self.data )
	EntityService:SpawnEntity( self.bp, self.entity, EntityService:GetTeam( self.entity ))
	EntityService:DissolveEntity( self.mesh, 0.2 ) 
	EntityService:DissolveEntity( self.entity, 0.2 ) 
end

return acid_undergound_mushroom
 