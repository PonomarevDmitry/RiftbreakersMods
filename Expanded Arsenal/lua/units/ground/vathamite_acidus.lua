require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'vathamite_acidus' ( base_unit )

function vathamite_acidus:__init()
	base_unit.__init(self, self)
end

function vathamite_acidus:init()
	SetupUnitScale( self.entity, self.data )
	self:RegisterHandler( self.entity, "PrepareSuecideEvent",  "OnPrepareSuecideEvent" )
	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "divide", { enter="OnDivide" } )
	self.soundFSM = self:CreateStateMachine()
	self.soundFSM:AddState( "silence", {interval=0.5} )
	self.soundFSM:AddState( "idle", {enter="_OnIdleEnter", execute="_OnIdleExecute", interval=0.5} )
	self.soundFSM:ChangeState("idle")
	
	self.stateTimer = 0.0
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
	self.allowDivideHealthInPercentage = 70
	self.divideScaleMul = 0.85
	self.wasDivided = false
end

function vathamite_acidus:OnDestroyRequest( evt )
	if ( EntityService:GetUnitCurrentSpeed( self.entity ) > 5.0 ) then
		EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(), "wreck_small", 0 )
	else
		EntityService:RequestDestroyPattern( self.entity, "wreck" )
	end
	self.soundFSM:ChangeState("silence")
end


function vathamite_acidus:_OnIdleEnter( state )
	self.stateTimer = -math.random(0.0,10.0)
end
function vathamite_acidus:_OnIdleExecute( state, dt )
	self.stateTimer = self.stateTimer + dt
	
	if ( self.stateTimer > 8.0 ) then
		EffectService:AttachEffects( self.entity, "idle_random" )
		self.stateTimer = -math.random(0.0,8.0)
	end	
end

function vathamite_acidus:OnPrepareSuecideEvent( evt )
	EntityService:RequestDestroyPattern( self.entity, "suicide" )
	--EffectService:AttachEffects( self.entity, "suicide_dmg" ) or SpawnEntity
end

function vathamite_acidus:OnDamageEvent( evt )
	
	if ( self.wasDivided == false ) then
		local damageValue = evt:GetDamageValue()
		local maxHealth = HealthService:GetMaxHealth( self.entity )

		local clonesNumber = self.data:GetIntOrDefault( "clones_number", 3 )

		if ( ( clonesNumber > 0 ) and ( damageValue < maxHealth ) ) then
			local currentHealthInPercentage = HealthService:GetHealthInPercentage( self.entity ) * 100
	
			if ( self.allowDivideHealthInPercentage >= currentHealthInPercentage ) then
				self.wasDivided = true
				EffectService:SpawnEffects( self.entity, "divide" )
				self.fsm:ChangeState( "divide" )
			end
		end
	end

end

function vathamite_acidus:OnDivide( state )
	for i = 1, self.data:GetIntOrDefault( "clones_number", 3 ) do			
		local entity = EntityService:SpawnEntity( self.data:GetString( "clone_bp" ), self.entity, "wave_enemy" )
		UnitService:SetInitialState( entity, UNIT_AGGRESSIVE);

		local scaleMin = self.data:GetFloatOrDefault( "min_scale", 1.0 )
		local scaleMax = self.data:GetFloatOrDefault( "max_scale", 1.0 )

		local db = EntityService:GetDatabase( entity )

		db:SetFloat( "min_scale", scaleMin * self.divideScaleMul )
		db:SetFloat( "max_scale", scaleMax * self.divideScaleMul )

		SetupUnitScale( entity, db )
	end

	EntityService:RemoveEntity( self.entity )
end



return vathamite_acidus