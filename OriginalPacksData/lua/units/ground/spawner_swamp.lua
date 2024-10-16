local base_spawner = require("lua/units/ground/spawner.lua")
class 'spawner_swamp' ( base_spawner )

function spawner_swamp:__init()
	base_spawner.__init(self, self)
end

function spawner_swamp:OnInit()
	self:RegisterHandler( self.entity, "ShootEvent",  "OnShootEvent" )
	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function spawner_swamp:OnShootEvent( evt )
	WeaponService:ShootOnce( self.entity )
end

return spawner_swamp
