local weapon = require("lua/items/weapon.lua")

class 'melee_weapon' ( weapon )

function melee_weapon:__init()
	weapon.__init(self,self)
end

function melee_weapon:OnInit()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { execute="OnUpdate"} )
end

function melee_weapon:OnEquipped()
	weapon.OnEquipped( self )
	self.dash_attacking = 0
	self.is_attacking = 0
	self.is_deactivating = 0
	self.combo_count = 0
	self.fsm:ChangeState( "update" )

	self.leftAttack = "melee_left_attack_1"
	self.rightAttack = "melee_right_attack_1"
	self.leftDashAttack = "melee_left_dash_attack_1"
	self.rightDashAttack = "melee_right_dash_attack_1"
	self.doubleAttack = "melee_double_attack_1"
end

function melee_weapon:OnUpdate()
	if self.is_attacking == 1 then
		local database = EntityService:GetDatabase( self.owner )
		if database == nil then 
			return
		end

		local dashing = 0
		if database:HasInt( "is_dashing" ) then
			dashing = database:GetInt( "is_dashing" ) 
		end

		if dashing == 1 then 
			if self.dash_attacking == 0 then 
				WeaponService:ForceStopMeleeAttack( self.item )
				local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
				if doubleWeapon ~= INVALID_ID then
					WeaponService:ForceStopMeleeAttack( doubleWeapon )
				end
				ItemService:SetActivationStatus( self.entity, true )
				self:RequestDashAttack()
				self.dash_attacking = 1
			end
		else
			if self.dash_attacking == 0 then
				ItemService:SetActivationStatus( self.entity, true )
				self:RequestAttack()
			end
		end

		local combo_count = WeaponService:GetMeleeComboCount(self.item)
		if self.combo_count < combo_count then
			self.combo_count = combo_count
			self:SetPadTriggerParams("melee_start", 0.1)
		end
	end

	if self.dash_attacking == 1 then
		if WeaponService:IsMeleeReady( self.item ) == true then
			self.dash_attacking = 0
		end
	end

	if self.is_deactivating == 1 then
		if WeaponService:IsMeleeReady( self.item ) == true then
			ItemService:SetActivationStatus( self.entity, false )
			self:OnAttackEnd()
			self.is_deactivating = 0
			self.dash_attacking = 0
		end
	end
end

function melee_weapon:OnActivate()
	local database = EntityService:GetDatabase(self.owner)
	if database == nil then 
		return
	end

	if database:HasFloat( "damage_resisted_stun_speed" ) then
		if database:GetFloat( "damage_resisted_stun_speed" ) > 0.0 then 
			return
		end
	end

	if self.is_attacking == 0 then
		self:OnMeleeAttackButtonPressed()
		self:OnAttackStart()
		self.is_attacking = 1
		self.combo_count = 0
	end
	self.is_deactivating = 0
end

function melee_weapon:OnDeactivate( forced )
	if self.is_attacking == 1 then
		self:OnMeleeAttackButtonReleased()

		self.is_attacking = 0
	end

	if forced == false then
		self.is_deactivating = 1
		return false
	else
		ItemService:SetActivationStatus( self.entity, false )
		WeaponService:ForceStopMeleeAttack( self.item )
		local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
		if doubleWeapon ~= INVALID_ID then
			WeaponService:ForceStopMeleeAttack( doubleWeapon )
		end
		self:OnAttackEnd()
		self.is_deactivating = 0
		self.dash_attacking = 0
	end
	return true
end

function melee_weapon:CanInterruptOnBlockRequest()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		return false
	end
	if WeaponService:IsInterruptBlocked( self.item ) then
		return false
	end
	return true
end

function melee_weapon:CanPassInterrupt()
	if WeaponService:IsInterruptBlocked( self.item ) then
		return false
	end
	return true
end

function melee_weapon:OnUnequipped()
	weapon.OnUnequipped( self )
	local state_name = self.fsm:GetCurrentState()
	if state_name ~= "" then 
		self.fsm:GetState( state_name ):Exit()
	end
end

function melee_weapon:RequestDashAttack()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		if self.slot == "LEFT_HAND" then
			if WeaponService:TryMeleeAttack( self.item, self.leftDashAttack ) then
				WeaponService:ForceStopMeleeAttack( doubleWeapon )
			end
		elseif self.slot == "RIGHT_HAND" then
			if WeaponService:TryMeleeAttack( self.item, self.rightDashAttack ) then
				WeaponService:ForceStopMeleeAttack( doubleWeapon )
			end
		end
	else
		if self.slot == "LEFT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.leftDashAttack )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.rightDashAttack )
		end
	end
end

function melee_weapon:RequestAttack()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		local fireRate1 = WeaponService:GetWeaponFireRate( self.item )
		local fireRate2 = WeaponService:GetWeaponFireRate( doubleWeapon )
		if fireRate1 < fireRate2 then
			if WeaponService:TryMeleeAttack( self.item, self.doubleAttack ) then
				WeaponService:TryMeleeMirrorAttack( doubleWeapon, self.doubleAttack )
			end
		else
			if WeaponService:TryMeleeAttack( self.item, self.doubleAttack ) then
				WeaponService:TryMeleeMirrorAttack( doubleWeapon, self.doubleAttack )
			end
		end
	else
		if self.slot == "LEFT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.leftAttack )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.rightAttack )
		end
	end
end

function melee_weapon:OnMeleeAttackButtonPressed()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		WeaponService:OnMeleeAttackButtonPressed( self.item, self.doubleAttack )
		WeaponService:OnMeleeAttackButtonPressed( doubleWeapon, self.doubleAttack )
	else
		if self.slot == "LEFT_HAND" then
			WeaponService:OnMeleeAttackButtonPressed( self.item, self.leftAttack )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:OnMeleeAttackButtonPressed( self.item, self.rightAttack )
		end
	end
end

function melee_weapon:OnMeleeAttackButtonReleased()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		WeaponService:OnMeleeAttackButtonReleased( self.item, self.doubleAttack )
		WeaponService:OnMeleeAttackButtonReleased( doubleWeapon, self.doubleAttack )
	else
		if self.slot == "LEFT_HAND" then
			WeaponService:OnMeleeAttackButtonReleased( self.item, self.leftAttack )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:OnMeleeAttackButtonReleased( self.item, self.rightAttack )
		end
	end
end

function melee_weapon:OnAttackStart()

end

function melee_weapon:OnAttackEnd()

end

return melee_weapon
