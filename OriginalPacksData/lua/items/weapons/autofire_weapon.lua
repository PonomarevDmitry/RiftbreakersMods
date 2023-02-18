local weapon = require("lua/items/weapon.lua")

class 'autofire_weapon' ( weapon )

function autofire_weapon:__init()
	item.__init(self,self)
end

function autofire_weapon:OnInit()
	self.animSpeed = self.data:GetFloatOrDefault("animation_speed", 1.0 )
end

function autofire_weapon:OnEquipped()
	weapon.OnEquipped( self )
end

function autofire_weapon:OnActivate()
    WeaponService:StartShoot( self.item );
	local db = EntityService:GetDatabase( self.item )
	if db ~= nil then
		db:SetFloat("is_shooting", 1.0 * self.animSpeed )
	end
end

function autofire_weapon:OnDeactivate()
    WeaponService:StopShoot( self.item );
	local db = EntityService:GetDatabase( self.item )
	if db ~= nil then
		db:SetFloat("is_shooting", 0.0  )
	end
	return true
end

function autofire_weapon:OnShootingStop()
	weapon.OnShootingStop( self )

	EffectService:AttachEffects( self.item, "shooting_end" ) 
end

return autofire_weapon
