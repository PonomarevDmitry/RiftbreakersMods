require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'stregaros_boss_intercept' ( alien_intercept )

function stregaros_boss_intercept:__init()
	alien_intercept.__init(self, self)
end

function stregaros_boss_intercept:OnInit()
	self:RegisterHandler( self.entity, "ResetShieldEvent", "OnResetShieldEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	
	self.shieldFSM = self:CreateStateMachine()
	self.shieldFSM:AddState( "wait", {} )
	self.shieldFSM:AddState( "reset", {enter="OnResetEnter", execute="OnResetExecute" } )

	UnitService:SetStateMachineParam( self.entity, "can_shield", 1 )

	self.shieldTimer		= 5.0
	self.currentShieldTimer = self.shieldTimer

	self.isShieldReady     = true
	self.isAlwaysShielding = false
	
	alien_intercept.OnInit(self)
end

function stregaros_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function stregaros_boss_intercept:OnResetShieldEvent( evt )
	--LogService:Log( "stregaros_boss_intercept:OnResetShieldEvent" )

	self.shieldTimer = evt:GetCooldown()

	local shieldState = self.data:GetStringOrDefault( "shield_state", "none" )
	self.data:SetString( "shield_state", "none" )

	if ( ( self.isAlwaysShielding == true ) and ( self.isShieldReady == true ) and ( evt:GetReason() == "stun" ) and ( shieldState == "none" ) ) then
		UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 1 )
		self.isShieldReady = false
	else
		self.shieldFSM:ChangeState( "reset" )
	end

end

function stregaros_boss_intercept:OnResetEnter( state )
	self.currentShieldTimer = self.shieldTimer
	UnitService:SetStateMachineParam( self.entity, "can_shield", 0 )
	UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 0 )
	self.isShieldReady = false
end

function stregaros_boss_intercept:OnResetExecute( state, dt )
	self.currentShieldTimer = self.currentShieldTimer - dt
	if ( self.currentShieldTimer <= 0 ) then
		UnitService:SetStateMachineParam( self.entity, "can_shield", 1 )
		self.isShieldReady = true
		self.shieldFSM:ChangeState( "wait" )
	end
end

function stregaros_boss_intercept:OnDamageEvent( evt )
	if ( self.isShieldReady == true ) then
		if ( ( damageType == "physical" ) or ( damageType == "energy" ) or ( damageType == "acid" ) or ( damageType == "cryo" ) ) then
			UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 1 )
			self.isAlwaysShielding = true
		end 
	end
end

return stregaros_boss_intercept
