require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'stregaros' ( base_unit )

function stregaros:__init()
	base_unit.__init(self, self)
end

function stregaros:OnInit()
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

end

function stregaros:OnResetShieldEvent( evt )
	--LogService:Log( "stregaros:OnResetShieldEvent" )

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

function stregaros:OnResetEnter( state )
	self.currentShieldTimer = self.shieldTimer
	UnitService:SetStateMachineParam( self.entity, "can_shield", 0 )
	UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 0 )
	self.isShieldReady = false
end

function stregaros:OnResetExecute( state, dt )
	self.currentShieldTimer = self.currentShieldTimer - dt
	if ( self.currentShieldTimer <= 0 ) then
		UnitService:SetStateMachineParam( self.entity, "can_shield", 1 )
		self.isShieldReady = true
		self.shieldFSM:ChangeState( "wait" )
	end
end

function stregaros:OnDamageEvent( evt )
	if ( self.isShieldReady == true ) then
		if ( ( damageType == "physical" ) or ( damageType == "energy" ) or ( damageType == "acid" ) or ( damageType == "cryo" ) ) then
			UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 1 )
			self.isAlwaysShielding = true
		end 
	end
end

return stregaros
