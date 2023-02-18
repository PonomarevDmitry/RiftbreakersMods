require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'nurglax' ( base_unit )

function nurglax:__init()
	base_unit.__init(self, self)
end

function nurglax:OnInit()
	self:RegisterHandler( self.entity, "ShootArtilleryEvent",  "OnShootArtilleryEvent" )
	self:RegisterHandler( self.entity, "PrepareArtilleryEvent",  "OnPrepareArtilleryEvent" )

	self.wreck_type = "wreck_big";
	self.wreckMinSpeed = 4

	self.fakeProjectile = INVALID_ID
	self.fakeProjectileBp = ""
	self.projectileBp = ""
	self.fakeProjectileScale = 0.0
	self.cocoonGrowSpeed = 1.0

	self.fakeProjectileFSM = self:CreateStateMachine()
	self.fakeProjectileFSM:AddState( "start_fake_projectile", { execute="OnFakeProjectileExecute" } )
	self.fakeProjectileFSM:AddState( "stop_fake_projectile", {  } )

	UnitService:SetStateMachineParam( self.entity, "cocoon_ready", 0 )
end

function nurglax:OnLoad()
	base_unit.OnLoad(self)
	if ( UnitService:GetStateMachineParamInt( self.entity, "cocoon_ready" ) == NO_STATE_MACHINE_PARAM ) then
		LogService:Log( "nurglax:OnLoad() - cocoon_ready patch" )
		UnitService:SetStateMachineParam( self.entity, "cocoon_ready", 1 )
	end
end


function nurglax:OnFakeProjectileExecute( state, dt )
	if ( self.fakeProjectileScale >= 1.0 ) then
		self.fakeProjectileFSM:ChangeState( "stop_fake_projectile" )
		UnitService:SetStateMachineParam( self.entity, "cocoon_ready", 1 )
	else
		self.fakeProjectileScale = self.fakeProjectileScale + ( ( 1.0 / self.cocoonGrowSpeed ) * dt )
		EntityService:SetScale( self.fakeProjectile, self.fakeProjectileScale, self.fakeProjectileScale, self.fakeProjectileScale )
	end
end

function nurglax:OnShootArtilleryEvent( evt )
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	WeaponService:ShootArtilleryOnTargetOrigin( self.fakeProjectile, self.entity, targetOrigin.x, targetOrigin.y + 1.0, targetOrigin.z, self.projectileBp, "bomb_center" )

	EntityService:RemoveEntity( self.fakeProjectile )
	self.fakeProjectile = INVALID_ID
	self.fakeProjectileScale = 0.0
end

function nurglax:OnPrepareArtilleryEvent( evt )

	self.fakeProjectileBp   = evt:GetPrepareBlueprint()
	self.projectileBp		= evt:GetShootBlueprint()
	self.cocoonGrowSpeed    = evt:GetGrowSpeed()

	UnitService:SetStateMachineParam( self.entity, "cocoon_ready", 0 )

	if ( self.fakeProjectile == INVALID_ID ) then
		self.fakeProjectile = EntityService:SpawnAndAttachEntity( self.fakeProjectileBp, self.entity, "ball", "wave_enemy" )
		EntityService:SetScale( self.fakeProjectile, 0.01, 0.01, 0.01 )
	end

	self.fakeProjectileFSM:ChangeState( "start_fake_projectile" )
end

function nurglax:OnDestroyRequest( evt )
	if ( self.fakeProjectile ~= INVALID_ID ) then		
		local pos = EntityService:GetPosition( self.entity )
		local ammo = WeaponService:ShootArtilleryOnTargetOrigin( self.fakeProjectile, self.entity, pos.x, pos.y, pos.z, self.projectileBp, "bomb_center" )
		
		if ( ammo ~= INVALID_ID ) then
			EntityService:RemoveComponent( ammo, "MeshComponent" )
			EntityService:SpawnEntity( "effects/enemies_nurglax/death_artillery_explosion", ammo, "" )
			EntityService:RemoveEntity( self.fakeProjectile )
			QueueEvent( "AmmoRemoveRequest", ammo )
		end
	end
end

return nurglax
