require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'octabit' ( base_unit )

function octabit:__init()
	base_unit.__init(self, self)
end

function octabit:OnInit()

	self:RegisterHandler( event_sink , "SunsetStartedEvent", "OnSunsetStartedEvent" )
	self:RegisterHandler( event_sink , "DayStartedEvent", "OnDayStartedEvent")
	self:RegisterHandler( event_sink , "NightStartedEvent", "OnNightStartedEvent")
	self:RegisterHandler( self.entity, "PrepareSuecideEvent",  "OnPrepareSuecideEvent" )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "check_eating", { execute="OnCheckEating", interval=1.0} )
	self.fsm:AddState( "divide", { enter="OnDivide" } )
	self.fsm:ChangeState( "check_eating" )

	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
	self.allowDivideHealthInPercentage = 70
	self.divideScaleMul = 0.85
	
	self.canEat = EnvironmentService:GetTimeOfDay()
	self.wasDivided = false

	self:UpdateEating()
end

function octabit:OnPrepareSuecideEvent( evt )
	EntityService:RequestDestroyPattern( self.entity, "suicide" )
	--EffectService:AttachEffects( self.entity, "suicide_dmg" ) or SpawnEntity
end

function octabit:OnDamageEvent( evt )
	
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

function octabit:OnDivide( state )
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

function octabit:UpdateEating()
	local isRaining = EnvironmentService:IsRaining()

	if ( isRaining or not self.canEat ) then
		UnitService:SetStateMachineParam( self.entity, "can_eat", 0 )
		return
	end

	if ( self.canEat ) then
		UnitService:SetStateMachineParam( self.entity, "can_eat", 1 )
	end	
end

function octabit:OnDayStartedEvent( evt )
	self.canEat = true
end

function octabit:OnSunsetStartedEvent( evt )
	self.canEat = false
end

function octabit:OnNightStartedEvent( evt )
	self.canEat = false
end

function octabit:OnCheckEating( state , dt)
	self:UpdateEating()
end

return octabit
