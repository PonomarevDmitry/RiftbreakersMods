local melee_weapon = require("lua/items/weapons/melee_weapon.lua")

class 'spear_weapon' ( melee_weapon )

function spear_weapon:__init()
	melee_weapon.__init(self,self)
end

function spear_weapon:OnEquipped()
	melee_weapon.OnEquipped( self )

	self.leftAttack = "spear_left_attack_1"
	self.rightAttack = "spear_right_attack_1"
	self.leftDashAttack = "spear_left_dash_attack_1"
	self.rightDashAttack = "spear_right_dash_attack_1"
	self.doubleAttack = "spear_double_attack_1"
end

return spear_weapon