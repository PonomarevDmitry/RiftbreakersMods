require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'lesigian' ( base_unit )

function lesigian:__init()
	base_unit.__init(self, self)
end

function lesigian:OnInit()
	self:RegisterHandler( self.entity, "EnterTeleportEvent",  "OnEnterTeleportEvent" )
	self:RegisterHandler( self.entity, "ExitTeleportEvent",  "OnExitTeleportEvent" )
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )

	self.wreck_type =  "wreck_big";
	self.wreckMinSpeed = 4

	self.isTeleporting = false

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function lesigian:OnShootEvent( evt )
	WeaponService:ShootOnce( self.entity )
end

function lesigian:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 

	if( markerName == "fuse_start" ) then
		UnitService:SpawnFuse( self.entity, "units/ground/lesigian/teleport_fuse", 0.75, "teleport" )
	end
	if( markerName == "gather_energy" ) then
		EffectService:AttachEffects( self.entity, "gather_energy" )
	end	

	return true
end


function lesigian:OnEnterTeleportEvent( evt )
	if ( self.isTeleporting == false ) then
		self.isTeleporting = true
		EntityService:FadeEntity( self.entity, DD_FADE_OUT, 1.0 )
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

function lesigian:OnExitTeleportEvent( evt )
	if ( self.isTeleporting == true ) then
		self.isTeleporting = false
		EntityService:FadeEntity( self.entity, DD_FADE_IN, 1.0 )
		EffectService:AttachEffects( self.entity, "teleport" )
	end
end

return lesigian
