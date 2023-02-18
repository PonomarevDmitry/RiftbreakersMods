local weapon = require("lua/items/weapon.lua")

class 'singlefire_weapon' ( weapon )

function singlefire_weapon:__init()
	weapon.__init(self,self)
end

function singlefire_weapon:OnInit()

end

function singlefire_weapon:OnEquipped()
	weapon.OnEquipped( self )
end

function singlefire_weapon:OnActivate()
    WeaponService:ShootOnce( self.item );
end

function singlefire_weapon:OnDeactivate()
	return true
end


return singlefire_weapon
