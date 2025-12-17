local melee_weapon = require("lua/items/weapons/melee_weapon.lua")

class 'fist_weapon' ( melee_weapon )

function fist_weapon:__init()
	melee_weapon.__init(self,self)
end

function fist_weapon:OnEquipped()
	melee_weapon.OnEquipped( self )

	self.leftAttack = "fist_left_attack_1"
	self.rightAttack = "fist_right_attack_1"
	self.leftDashAttack = "fist_left_dash_attack_1"
	self.rightDashAttack = "fist_right_dash_attack_1"
	self.doubleAttack = "fist_double_attack_1"

	self.mirrorItem = nil
end

function fist_weapon:OnAttackStart()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon == INVALID_ID then
		self:CleanupMirrorFist()
		if self.slot == "LEFT_HAND" then
			local itemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
			QueueEvent( "FadeEntityOutRequest", itemEnt, 0.2 , true)
			self:CreateMirrorFist( "att_r_hand_item")
			EntityService:FadeEntity( self.mirrorItem, DD_FADE_IN, 0.2 )
		else
			local itemEnt = ItemService:GetEquippedPresentationItem( self.owner, "LEFT_HAND" )
			QueueEvent( "FadeEntityOutRequest", itemEnt, 0.2 , true)
			self:CreateMirrorFist( "att_l_hand_item" )
			EntityService:FadeEntity( self.mirrorItem, DD_FADE_IN, 0.2 )
		end
	end
end

function fist_weapon:OnAttackEnd()
	local doubleWeapon = WeaponService:GetSameWeaponEquipped( self.owner, self.entity )
	if doubleWeapon == INVALID_ID then
		if self.slot == "LEFT_HAND" then
			local itemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
			EntityService:FadeEntity( itemEnt, DD_FADE_IN, 0.2 )
			self:CleanupMirrorFist()
		else
			local itemEnt = ItemService:GetEquippedPresentationItem( self.owner, "LEFT_HAND" )
			EntityService:FadeEntity( itemEnt, DD_FADE_IN, 0.2 )
			self:CleanupMirrorFist()
		end
	end
end

function fist_weapon:CleanupMirrorFist()
	if self.mirrorItem ~= nil then
		QueueEvent("DissolveEntityRequest", self.mirrorItem, 0.2, 0.0 )
		self.mirrorItem = nil
	end
end

function fist_weapon:CreateMirrorFist( attachment )
	local meshId = EntityService:GetMeshName( self.item )
	local materialId = EntityService:GetOverridenMaterial( self.item )
	self.mirrorItem = EntityService:SpawnAndAttachEntity( self.owner, attachment )
	EntityService:CreateComponent( self.mirrorItem, "MeshComponent" )
	EntityService:CreateComponent( self.mirrorItem, "BoundsComponent" )
	EntityService:ChangeMesh( self.mirrorItem, WeaponService:GetMirrorMeshName( meshId ) )
	EntityService:ChangeMaterial( self.mirrorItem, materialId )
	EntityService:FadeEntity( self.mirrorItem, DD_FADE_IN, 0.0 )

end

return fist_weapon