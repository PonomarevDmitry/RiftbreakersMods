local melee_weapon = require("lua/items/weapons/melee_weapon.lua")

class 'sword_weapon' ( melee_weapon )

function sword_weapon:__init()
	melee_weapon.__init(self,self)
end

function sword_weapon:OnEquipped()
	melee_weapon.OnEquipped( self )

	self.leftAttack = "melee_left_attack_1"
	self.rightAttack = "melee_right_attack_1"
	self.leftDashAttack = "melee_left_dash_attack_1"
	self.rightDashAttack = "melee_right_dash_attack_1"
	self.doubleAttack = "melee_double_attack_1"
end

return sword_weapon