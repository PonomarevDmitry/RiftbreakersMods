local item = require("lua/items/item.lua")

class 'dodge_roll' ( item )

function dodge_roll:__init()
	item.__init(self,self)
end

function dodge_roll:OnInit()
	self:InitDodgeRoll()
end

function dodge_roll:InitDodgeRoll()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "rolling", { from="*", enter="OnRollEnter", execute="OnRollExecute", exit="OnRollExit"} )

	self.rollStartSpeed = self.data:GetFloatOrDefault("roll_animation_start_speed", 0.5 )
	self.rollEndSpeed = self.data:GetFloatOrDefault("roll_animation_end_speed", 2.0 )
	self.rollAccelerationTime = self.data:GetFloatOrDefault("roll_animation_acceleration_time", 1.0 )
	self.rollCooldown = self.data:GetFloatOrDefault("roll_cooldown", 2.0 )
	self.rollDuration = self.data:GetFloatOrDefault("roll_duration", 4.0 )
	
	self.isDashing = false
	self.firstDeactivate = true
	self.damageEnt = INVALID_ID
end

function dodge_roll:OnLoad()
	item.OnLoad(self)

	if ( self.dodgeRollVersion == nil or self.dodgeRollVersion < 1 ) then

		if self.machine ~= nil then
			self:DestroyStateMachine( self.machine )
			self.machine = nil
		end

		self:InitDodgeRoll()
		self.dodgeRollVersion = 1
	end
end

function dodge_roll:OnEquipped()
	if not self:HasEventHandler( self.owner, "AnimationMarkerReached" ) then
		self:RegisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	end

	local db = EntityService:GetDatabase( self.owner )
	if db then
		db:SetFloat( "roll_speed", self.rollStartSpeed)
	end
end

function dodge_roll:ActiveDodgeRoll()
	self.machine:ChangeState("rolling")

	EntityService:Dash( self.owner, self.item )

	EntityService:DisableCollisions( self.owner )
	HealthService:SetImmortality( self.owner, true )
	EntityService:ChangeCharacterControllerGroupId( self.owner, "debris" )

	local db = EntityService:GetDatabase( self.entity );
	if db then 
		local damageBp = db:GetStringOrDefault( "damage_bp", "items/skills/dodge_roll_weapon" )
		if damageBp ~= "" then
			self.damageEnt = EntityService:SpawnAndAttachEntity( damageBp, self.item, "" )
			EntityService:PropagateEntityOwner( self.damageEnt, self.entity )
			WeaponService:TryMeleeAttack( self.damageEnt, "attack_1" )
		end
	end

	self.lastLeftItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "LEFT_HAND" )
	self.lastRightItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )

	EntityService:FadeEntity( self.lastLeftItemEnt, DD_FADE_OUT, 0.75)
	EntityService:FadeEntity( self.lastRightItemEnt, DD_FADE_OUT, 0.75)

	self.isDashing = true
	self.firstDeactivate = true
end

function dodge_roll:DeactivateDodgeRoll()
	local odb = EntityService:GetDatabase( self.owner )
	if odb then
		odb:SetInt( "is_rolling", 0 )
	end

	self.machine:Deactivate()

	EntityService:EnableCollisions( self.owner )
	HealthService:SetImmortality( self.owner, false )
	EntityService:ChangeCharacterControllerGroupId( self.owner, "character" )

	if self.damageEnt ~= INVALID_ID then
		EntityService:RemoveEntity( self.damageEnt )
		self.damageEnt = INVALID_ID
	end
	
	local db = EntityService:GetDatabase( self.entity );
	local splashBp = db:GetStringOrDefault( "splash_bp", "effects/items/dodge_roll_explosion_standard" )
	if splashBp ~= "" then
		local splashEnt = EntityService:SpawnEntity( splashBp, self.item, "" ) 
		EntityService:PropagateEntityOwner( splashEnt, self.entity )
	end	

    ItemService:ResetCooldown( self.entity, self.rollCooldown )

	EntityService:FadeEntity( self.lastLeftItemEnt, DD_FADE_IN, 0.75)
	EntityService:FadeEntity( self.lastRightItemEnt, DD_FADE_IN, 0.75)

	self.lastLeftItemEnt = nil
	self.lastRightItemEnt = nil

	self.isDashing = false
end

function dodge_roll:OnActivate()
	if self.isDashing == false then
		self:ActiveDodgeRoll()
	elseif self.isDashing == true then 
		self:DeactivateDodgeRoll()
	end
end

function dodge_roll:OnDeactivate( forced )
	--LogService:Log( 'OnDeactivate ' .. tostring( forced ) .. ' ' .. tostring( self.isDashing ) .. ' ' .. tostring( self.firstDeactivate ) )
	if self.isDashing == true and self.firstDeactivate ~= true then 
		self:DeactivateDodgeRoll()
	end
	self.firstDeactivate = false
	return false 
end

function dodge_roll:CanInterruptOnBlockRequest()
	--if self.isDashing == true then 
		return false
	--end
	--return true
end

function dodge_roll:CanPassInterrupt()
	--if self.isDashing == true then 
		return false
	--end
	--return true
end

function dodge_roll:OnUnequipped()
	if self:HasEventHandler( self.owner, "AnimationMarkerReached" ) then
		self:UnregisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	end
end

function dodge_roll:OnRollEnter( state )
	state:SetDurationLimit( self.rollDuration )
end

function dodge_roll:OnRollExecute( state )
    local progress =  math.min( state:GetDuration() / self.rollAccelerationTime, 1.0 )
    local diff = self.rollEndSpeed - self.rollStartSpeed
    local rollSpeed = self.rollStartSpeed + ( progress * diff )
	local db = EntityService:GetDatabase( self.owner );
	if db then 
		db:SetFloat( "roll_speed", rollSpeed);
	end
end

function dodge_roll:OnRollExit( state )
	if self.isDashing == true then 
		self:DeactivateDodgeRoll()
	end
end

function dodge_roll:OnAnimationMarkerReached(evt)
	if  evt:GetMarkerName() == "roll_end" then
		EntityService:StopDash( self.owner );

		QueueEvent( "DeactivateItemRequest", self.entity, true )
	end
end

return dodge_roll
