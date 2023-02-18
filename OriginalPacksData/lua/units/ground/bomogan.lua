require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'bomogan' ( base_unit )

function bomogan:__init()
	base_unit.__init(self, self)
end

function bomogan:OnInit()
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self:RegisterHandler( self.entity, "PrepareArtilleryEvent",  "OnPrepareArtilleryEvent" )

	self.wreck_type 			= "wreck_big"
	self.wreckMinSpeed			= 4

	self.fakeProjectile			= INVALID_ID
	self.fakeProjectileBp		= ""
	self.projectileBp			= ""
	self.fakeProjectileScale	= 0.0
	self.projectileGrowSpeed	= 1.0

	self.fakeProjectileFSM = self:CreateStateMachine()
	self.fakeProjectileFSM:AddState( "start_fake_projectile", { execute="OnFakeProjectileExecute" } )
	self.fakeProjectileFSM:AddState( "stop_fake_projectile", {  } )
end

function bomogan:OnFakeProjectileExecute( state, dt )
	if ( self.fakeProjectileScale >= 1.0 ) then
		self.fakeProjectileFSM:ChangeState( "stop_fake_projectile" )
	else
		self.fakeProjectileScale = self.fakeProjectileScale + ( ( 1.0 / self.projectileGrowSpeed ) * dt )
		EntityService:SetScale( self.fakeProjectile, self.fakeProjectileScale, self.fakeProjectileScale, self.fakeProjectileScale )
	end
end

function bomogan:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	WeaponService:ShootArtilleryOnTargetOrigin( self.entity, self.entity, targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z, self.projectileBp, "att_artillery" )

	EntityService:RemoveEntity( self.fakeProjectile )
	self.fakeProjectile = INVALID_ID
	self.fakeProjectileScale = 0.0
end

function bomogan:OnPrepareArtilleryEvent( evt )

	self.fakeProjectileBp		= evt:GetPrepareBlueprint()
	self.projectileBp			= evt:GetShootBlueprint()
	self.projectileGrowSpeed    = evt:GetGrowSpeed()

	if ( self.fakeProjectile == INVALID_ID ) then
		self.fakeProjectile = EntityService:SpawnAndAttachEntity( self.fakeProjectileBp, self.entity, "att_artillery", "" )
		EntityService:SetScale( self.fakeProjectile, 0.0, 0.0, 0.0 )
	end

	self.fakeProjectileFSM:ChangeState( "start_fake_projectile" )
end

function bomogan:OnDestroyRequest( evt )
	if ( self.fakeProjectile ~= INVALID_ID ) then
		EntityService:DissolveEntity( self.fakeProjectile, 2.0 )
	end
	EffectService:AttachEffects( self.entity, "death_artillery" )
end

return bomogan
