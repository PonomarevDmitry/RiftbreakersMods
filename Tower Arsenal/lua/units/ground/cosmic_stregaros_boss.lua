require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'cosmic_stregaros_boss' ( base_unit )

function cosmic_stregaros_boss:__init()
	base_unit.__init(self, self)
end

function cosmic_stregaros_boss:OnInit()
	self:RegisterHandler( self.entity, "ResetShieldEvent", "OnResetShieldEvent" )
	self:RegisterHandler( self.entity, "DeathEvent", "OnDeathEvent" )

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 4
	
	self.shieldFSM = self:CreateStateMachine()
	self.shieldFSM:AddState( "wait", {} )
	self.shieldFSM:AddState( "reset", {enter="OnResetEnter", execute="OnResetExecute" } )

	UnitService:SetStateMachineParam( self.entity, "can_shield", 1 )

	self.shieldTimer		= 5.0
	self.currentShieldTimer = self.shieldTimer

	self.isShieldReady     = true
	self.isAlwaysShielding = false

	self.respawnTimer = 10.0 -- time to respawn after death
	self.isRespawning = false
end

function cosmic_stregaros_boss:OnResetShieldEvent( evt )
	--LogService:Log( "cosmic_stregaros_boss:OnResetShieldEvent" )

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

function cosmic_stregaros_boss:OnResetEnter( state )
	self.currentShieldTimer = self.shieldTimer
	UnitService:SetStateMachineParam( self.entity, "can_shield", 0 )
	UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 0 )
	self.isShieldReady = false
end

function cosmic_stregaros_boss:OnResetExecute( state, dt )
	self.currentShieldTimer = self.currentShieldTimer - dt
	if ( self.currentShieldTimer <= 0 ) then
		UnitService:SetStateMachineParam( self.entity, "can_shield", 1 )
		self.isShieldReady = true
		self.shieldFSM:ChangeState( "wait" )
	end
end

function cosmic_stregaros_boss:OnDamageEvent( evt )
	if ( self.isShieldReady == true ) then
		if ( ( damageType == "physical" ) or ( damageType == "energy" ) or ( damageType == "acid" ) or ( damageType == "cryo" ) ) then
			UnitService:SetStateMachineParam( self.entity, "move_always_with_shield_event", 1 )
			self.isAlwaysShielding = true
		end 
	end
end

function cosmic_stregaros_boss:OnDeathEvent( evt )
	self.isRespawning = true
	self.entity:SetHealth( 0 ) -- ensure the entity is dead
	self.entity:SetInvulnerable( true ) -- make the entity invulnerable while respawning
	self:RespawnTimer()
end

function cosmic_stregaros_boss:RespawnTimer()
	self.respawnTimer = self.respawnTimer - 1
	if ( self.respawnTimer <= 0 ) then
		self:Respawn()
	else
		self:ScheduleTimer( 5, "RespawnTimer" )
	end
end

function cosmic_stregaros_boss:Respawn()
	self.entity:SetHealth( self.entity:GetMaxHealth() ) -- restore the entity's health
	self.entity:SetInvulnerable( false ) -- make the entity vulnerable again
	self.isRespawning = true
	self.isShieldReady = true
	self.isAlwaysShielding = false
	self.shieldFSM:ChangeState( "wait" )
end

return cosmic_stregaros_boss
