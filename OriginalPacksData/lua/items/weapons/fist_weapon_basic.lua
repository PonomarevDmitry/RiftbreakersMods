local fist_weapon = require("lua/items/weapons/fist_weapon.lua")

class 'fist_weapon_basic' ( fist_weapon )

function fist_weapon_basic:__init()
	fist_weapon.__init(self,self)
end
function fist_weapon_basic:OnEquipped()
	fist_weapon.OnEquipped( self )
	self.slot = self.data:GetString( "override_slots");
	local ownerData = EntityService:GetDatabase( self.owner );
	ownerData:SetString( self.slot .. "_item_type", "melee_weapon" )
end

function fist_weapon_basic:OnUnequipped()
    fist_weapon.OnUnequipped( self )
end

return fist_weapon_basic