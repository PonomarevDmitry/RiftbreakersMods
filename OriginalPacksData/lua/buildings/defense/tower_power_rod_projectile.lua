require("lua/utils/table_utils.lua")
require("lua/units/units_utils.lua")

class 'tower_power_rod_projectile' ( LuaEntityObject )

function tower_power_rod_projectile:__init()
	LuaEntityObject.__init(self, self)
end

function tower_power_rod_projectile:init()
	self:RegisterHandler( self.entity, "AmmoRemoveRequest",  "OnAmmoRemoveRequest" )
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 1.0 )

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "impact", { from="*", enter="OnImpactEnter", exit="OnImpactExit" } )
	self.sm:AddState( "preshockwave", { from="*", enter="OnPreShockwaveEnter", exit="OnPreShockwaveExit" } )
	self.sm:AddState( "postshockwave", { from="*", enter="OnPostShockwaveEnter", exit="OnPostShockwaveExit" } )

	self.counter = self.data:GetIntOrDefault( "shockwave_count", 1 );
	self.destroy = false
end

function tower_power_rod_projectile:OnAmmoRemoveRequest()
	QueueEvent( "RemoveEffectsByGroupRequest", self.entity, "exhaust", 0.0 )
	EntityService:RemoveComponent( self.entity, "SimpleMovementComponent" )

	self.counter = self.counter - 1
	if self.counter >= 1 then 
		self.sm:ChangeState( "impact" )
	else
		EntityService:RequestDestroyPattern( self.entity, "default", true )	
	end
end

function tower_power_rod_projectile:OnImpactEnter( state )
	AnimationService:StartAnim( self.entity, "working", false, 1.0 )
	local animTime = AnimationService:GetAnimDuration( self.entity, "working" );
	state:SetDurationLimit( animTime )
end

function tower_power_rod_projectile:OnImpactExit( state )
	self.sm:ChangeState( "preshockwave" )
end

function tower_power_rod_projectile:OnPreShockwaveEnter( state )
	AnimationService:StartAnim( self.entity, "working", false, 1.0 )
	state:SetDurationLimit( 0.15 )
end

function tower_power_rod_projectile:OnPreShockwaveExit( state )
	self.sm:ChangeState( "postshockwave" )
	WeaponService:RequestProjectileExplosion( self.entity )

	if self.destroy then 
		EntityService:RequestDestroyPattern( self.entity, "default", true )	
	end
end

function tower_power_rod_projectile:OnPostShockwaveEnter( state )
	local animTime = AnimationService:GetAnimDuration( self.entity, "working" );
	state:SetDurationLimit( animTime - 0.15 )
end

function tower_power_rod_projectile:OnPostShockwaveExit( state )
	AnimationService:StopAnim( self.entity, "working" )
	self.counter = self.counter - 1
	if self.counter <= 0 then 
		self.destroy = true
	end
	self.sm:ChangeState( "preshockwave" )
end

return tower_power_rod_projectile
