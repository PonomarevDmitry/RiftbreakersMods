require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'hedroner' ( base_unit )

function hedroner:__init()
	base_unit.__init(self, self)
end

function hedroner:OnInit()

	self:RegisterHandler( self.entity, "EnterTeleportEvent",  "OnEnterTeleportEvent" )
	self:RegisterHandler( self.entity, "ExitTeleportEvent",  "OnExitTeleportEvent" )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 0
    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 1

	self.isTeleporting = false
	self.allowTeleportHealthInPercentage = 30

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )

	UnitService:SetStateMachineParam( self.entity, "can_teleport", 0 )
end

function hedroner:CheckHealth()
	local currentHealthInPercentage = HealthService:GetHealthInPercentage( self.entity ) * 100
	
	if ( self.allowTeleportHealthInPercentage >= currentHealthInPercentage ) then
		UnitService:SetStateMachineParam( self.entity, "can_teleport", 1 )
	else
		UnitService:SetStateMachineParam( self.entity, "can_teleport", 0 )
	end
end

function hedroner:OnLoad()
	base_unit.OnLoad(self)
	self:CheckHealth()
end

function hedroner:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "attack_range_1"  ) then
		local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
		WeaponService:ShootAmmoOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_1" )
	elseif( markerName == "attack_range_2" ) then
		local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
		WeaponService:ShootAmmoOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_2" )
	elseif( markerName == "fuse_start" ) then
		UnitService:SpawnFuse( self.entity, "units/ground/hedroner/teleport_fuse", 2.5, "teleport" )
	end

	return true
end

function hedroner:OnEnterTeleportEvent( evt )
	if ( self.isTeleporting == false ) then
		self.isTeleporting = true
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

function hedroner:OnExitTeleportEvent( evt )
	if ( self.isTeleporting == true ) then
		self.isTeleporting = false
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

function hedroner:OnDamageEvent( evt )
	self:CheckHealth()
end

return hedroner
