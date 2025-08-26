local melee_weapon = require("lua/items/weapons/melee_weapon.lua")

class 'chainsaw_weapon' ( melee_weapon )

function chainsaw_weapon:__init()
	melee_weapon.__init(self,self)
end

function chainsaw_weapon:OnEquipped()
	melee_weapon.OnEquipped( self )

	self.leftAttack = "chainsaw_left_attack_1"
	self.rightAttack = "chainsaw_right_attack_1"
	self.leftDashAttack = "chainsaw_left_dash_attack_1"
	self.rightDashAttack = "chainsaw_right_dash_attack_1"
	self.doubleAttack = "chainsaw_double_attack_1"

	self.hasEventHandler = true
	self:RegisterHandler( event_sink, "DamageThresholdedEvent", "OnDamageThresholdedEvent" )
end

function chainsaw_weapon:OnUnequipped()
	melee_weapon.OnUnequipped( self ) 

	if self.hasEventHandler then
		self.hasEventHandler = false
		self:UnregisterHandler( event_sink, "DamageThresholdedEvent", "OnDamageThresholdedEvent" )
	end
end 

function chainsaw_weapon:OnActivate(activation_id)
	melee_weapon.OnActivate( self, activation_id )
	AnimationService:StartAnim( self.item, "attack", true )
end

function chainsaw_weapon:OnDeactivate( forced )
	melee_weapon.OnDeactivate( self, true )
	AnimationService:StopAnim( self.item, "attack" )
end

function chainsaw_weapon:OnDamageThresholdedEvent( evt )
	if evt:GetCreator() == self.item then 
		local target = evt:GetEntity()
		local minDamageThreshold = HealthService:GetMinDamageThreshold( target )
		local dps = WeaponService:GetWeaponDps( self.entity )
		if minDamageThreshold < dps then
			QueueEvent( "DamageRequest", target, dps, "physical", 1, 0 )
		end
	end
end

return chainsaw_weapon