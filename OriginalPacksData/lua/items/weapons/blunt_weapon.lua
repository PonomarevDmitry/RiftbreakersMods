local melee_weapon = require("lua/items/weapons/melee_weapon.lua")

class 'blunt_weapon' ( melee_weapon )

function blunt_weapon:__init()
	melee_weapon.__init(self,self)
end

function blunt_weapon:OnEquipped()
	melee_weapon.OnEquipped( self )

	self.leftAttack = "blunt_left_attack_1"
	self.rightAttack = "blunt_right_attack_1"
	self.leftDashAttack = "blunt_left_dash_attack_1"
	self.rightDashAttack = "blunt_right_dash_attack_1"
	self.doubleAttack = "blunt_double_attack_1"
end

return blunt_weapon
