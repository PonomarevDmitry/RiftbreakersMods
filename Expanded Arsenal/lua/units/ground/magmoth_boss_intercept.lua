require("lua/utils/table_utils.lua")

local alien_intercept = require("lua/units/ground/alien_intercept.lua")
class 'magmoth_boss_intercept' ( alien_intercept )

function magmoth_boss_intercept:__init()
	alien_intercept.__init(self, self)
end

function magmoth_boss_intercept:OnInit()

	self:RegisterHandler( self.entity, "EnterTeleportEvent",  "OnEnterTeleportEvent" )
	self:RegisterHandler( self.entity, "ExitTeleportEvent",  "OnExitTeleportEvent" )
	self.fuseBp = self.data:GetStringOrDefault("fuse_bp", "effects/enemies_generic/teleport_trail_fire")
	
	self.wreck_type =  "wreck_big";
	self.wreckMinSpeed = 4

	self.isTeleporting = false

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
	
	alien_intercept.OnInit(self)
end

function magmoth_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function magmoth_boss_intercept:OnLoad()
	alien_intercept.OnLoad(self)
	self.fuseBp = self.data:GetStringOrDefault("fuse_bp", "effects/enemies_generic/teleport_trail_fire")
end

function magmoth_boss_intercept:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "attack_range_1"  ) then
		local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
		WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_1" )
	elseif( markerName == "attack_range_2" ) then
		local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), "range_attack_origin" )
		WeaponService:ShootProjectileOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 0.5, targetOrigin.z, "att_shoot_2" )
	elseif( markerName == "fuse_start" ) then
		UnitService:SpawnFuse( self.entity, self.fuseBp, 0.65, "teleport" )
	end

	return true
end

function magmoth_boss_intercept:OnEnterTeleportEvent( evt )
	if ( self.isTeleporting == false ) then
		self.isTeleporting = true
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

function magmoth_boss_intercept:OnExitTeleportEvent( evt )
	if ( self.isTeleporting == true ) then
		self.isTeleporting = false
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

return magmoth_boss_intercept
