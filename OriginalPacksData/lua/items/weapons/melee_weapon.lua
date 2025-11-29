local weapon = require("lua/items/weapon.lua")

class 'melee_weapon' ( weapon )

function melee_weapon:__init()
	weapon.__init(self,self)
	self.activation_id = 0
end

function melee_weapon:OnInit()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { execute="OnUpdate"} )
end

function melee_weapon:GetWeaponEntity()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		local fireRate1 = WeaponService:GetWeaponFireRate( self.item )
		local fireRate2 = WeaponService:GetWeaponFireRate( doubleWeapon )
		if fireRate1 < fireRate2 then
			return self.item
		else
			return doubleWeapon
		end
	end
	return self.item
end

function melee_weapon:IsAttacking()
	local weapon_entity = self:GetWeaponEntity()
	
	if WeaponService:IsMeleeAttackButtonPressed( weapon_entity, "" ) then
		return 1
	else
		return 0
	end
end

function melee_weapon:IsAnyAttacking()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		if WeaponService:IsMeleeAttackButtonPressed( self.item, "" ) or WeaponService:IsMeleeAttackButtonPressed( doubleWeapon, "" ) then
			return 1
		else
			return 0
		end
	end
	if WeaponService:IsMeleeAttackButtonPressed( self.item, "" )  then
		return 1
	else
		return 0
	end
end


function melee_weapon:IsDeactivating()
	local activationStatus = ItemService:GetActivationStatus( self.entity );
	local deactivating = not self:IsAnyAttacking( ) and activationStatus;
	return deactivating;
end


function melee_weapon:OnEquipped()
	weapon.OnEquipped( self )
	self.dash_attacking = 0
	self.is_deactivating = 0
	self.combo_count = 0
	self.activation_id = 0
	self.fsm:ChangeState( "update" )

	self.leftAttack = "melee_left_attack_1"
	self.rightAttack = "melee_right_attack_1"
	self.leftDashAttack = "melee_left_dash_attack_1"
	self.rightDashAttack = "melee_right_dash_attack_1"
	self.doubleAttack = "melee_double_attack_1"
end

function melee_weapon:OnUpdate()
	local activationStatus = ItemService:GetActivationStatus( self.entity );
	local is_attacking = self:IsAnyAttacking();

	if activationStatus == false then
		return
	end

	--LogService:Log( "melee_weapon:OnUpdate() ent " .. tostring( self.entity ) .. " item " .. tostring( self.entity ) .. " is attacking " .. tostring( is_attacking ) )

	local weapon_entity = self:GetWeaponEntity()
	if is_attacking == 1 then
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
				--LogService:Log( "set dash = 1 activation of " .. tostring( self.entity ) )
				ItemService:SetActivationStatus( self.entity, true )
				self:RequestDashAttack()
				self.dash_attacking = 1
			end
		else
			if self.dash_attacking == 0 then
				--LogService:Log( "set dash = 0 activation of " .. tostring( self.entity ) )
				ItemService:SetActivationStatus( self.entity, true )
				self:RequestAttack( self.activation_id )
			end
		end

		
		local combo_count = WeaponService:GetMeleeComboCount(weapon_entity)
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
		--LogService:Log( "deactivating == 1  ent " .. tostring( self.entity ) )
		if WeaponService:IsMeleeReady( self.item ) == true then
			--LogService:Log( "SetActivationStatus( false )" .. tostring( self.entity ) )
			ItemService:SetActivationStatus( self.entity, false )
			self:OnAttackEnd()
			self.is_deactivating = 0
			self.dash_attacking = 0
		end
	end
end

function melee_weapon:OnActivate( activation_id )
	local database = EntityService:GetDatabase(self.owner)
	if database == nil then 
		return
	end

	if database:HasFloat( "damage_resisted_stun_speed" ) then
		if database:GetFloat( "damage_resisted_stun_speed" ) > 0.0 then 
			return
		end
	end

	local is_attacking = self:IsAnyAttacking()
	if is_attacking == 0 then
		self:OnMeleeAttackButtonPressed( activation_id)
		self:OnAttackStart()
		self.combo_count = 0
		self.activation_id = activation_id
	end
	self.is_deactivating = 0
end

function melee_weapon:OnDeactivate( forced )
	local is_attacking = self:IsAnyAttacking();
	if is_attacking == 1 then
		self:OnMeleeAttackButtonReleased()
		--LogService:Log( "OnDeactivate, set is_attacking == 0 " )
	end

	if forced == false then
		--LogService:Log( "deactivating = 1" .. tostring( self.entity ) )
		self.is_deactivating = 1
		return false
	else
		--LogService:Log( "set ondeactivation of " .. tostring( self.entity ) )
		ItemService:SetActivationStatus( self.entity, false )
		WeaponService:ForceStopMeleeAttack( self.item )
		--LogService:Log( "ForceStopMeleeAttack" )
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
	if self.owner == nil then
		return true
	end
	local weapon_entity = self:GetWeaponEntity()
	if WeaponService:IsInterruptBlocked( weapon_entity ) then
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

function melee_weapon:RequestAttack( activationId )
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		local fireRate1 = WeaponService:GetWeaponFireRate( self.item )
		local fireRate2 = WeaponService:GetWeaponFireRate( doubleWeapon )
		if fireRate1 < fireRate2 then
			if WeaponService:TryMeleeAttack( self.item, self.doubleAttack, activationId ) then
				WeaponService:TryMeleeMirrorAttack( doubleWeapon, self.doubleAttack, activationId )
			end
		else
			if WeaponService:TryMeleeAttack( doubleWeapon, self.doubleAttack, activationId ) then
				WeaponService:TryMeleeMirrorAttack( self.item, self.doubleAttack, activationId )
			end
		end
	else
		if self.slot == "LEFT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.leftAttack, activationId )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:TryMeleeAttack( self.item, self.rightAttack, activationId )
		end
	end
end

function melee_weapon:OnMeleeAttackButtonPressed( activation_id )
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon ~= INVALID_ID then
		WeaponService:OnMeleeAttackButtonPressed( self.item, self.doubleAttack, activation_id )
		WeaponService:OnMeleeAttackButtonPressed( doubleWeapon, self.doubleAttack, activation_id )
		local fireRate1 = WeaponService:GetWeaponFireRate( self.item )
		local fireRate2 = WeaponService:GetWeaponFireRate( doubleWeapon )
		if fireRate1 < fireRate2 then
			WeaponService:OnMeleeAttackButtonReleased(doubleWeapon, self.doubleAttack  )
		else
			WeaponService:OnMeleeAttackButtonReleased(self.item, self.doubleAttack  )
		end

	else
		if self.slot == "LEFT_HAND" then
			WeaponService:OnMeleeAttackButtonPressed( self.item, self.leftAttack, activation_id )
		elseif self.slot == "RIGHT_HAND" then
			WeaponService:OnMeleeAttackButtonPressed( self.item, self.rightAttack, activation_id )
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
