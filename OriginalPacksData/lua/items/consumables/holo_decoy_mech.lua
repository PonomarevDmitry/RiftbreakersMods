class 'holo_decoy_mech' ( LuaEntityObject )
require("lua/utils/reflection.lua")

function holo_decoy_mech:__init()
	LuaEntityObject.__init(self,self)
end

function holo_decoy_mech:GetItemBlueprint( entity )
	local inventoryItem = EntityService:GetConstComponent( entity, "InventoryItemComponent" )
	if ( inventoryItem == nil ) then
		return ""
	end
	local helper = reflection_helper(inventoryItem)
	return helper.item_bp
end

function holo_decoy_mech:init()
	self.explodeTime = self.data:GetFloatOrDefault( "explode_time", 10 )
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "decoy", { enter="OnDecoyStart", exit="OnDecoyEnd" } )
	if self.data:HasFloat("explode_time") then 
		self.sm:ChangeState( "decoy" )
		end
	
	local pawn = PlayerService:GetPlayerControlledEnt( 0 )
	if (EntityService:IsAlive( pawn ) == false ) then return end
	
	
	local itemLeft = ItemService:GetEquippedItem( pawn, "LEFT_HAND" )
	if ( EntityService:IsAlive( itemLeft )  ) then
		local blueprint = self:GetItemBlueprint( itemLeft )
		if ( blueprint ~= "" ) then
			local leftSword = EntityService:SpawnAndAttachEntity( blueprint, self.entity, "att_l_hand_item","")
			EntityService:SetMaterial(leftSword, "selector/hologram_blue", "default")
		end
	end
	
	local itemRight = ItemService:GetEquippedItem( pawn, "RIGHT_HAND" )
	if ( EntityService:IsAlive( itemRight )  ) then
		local blueprint = self:GetItemBlueprint( itemRight )
		if ( blueprint ~= "" ) then
			local leftSword = EntityService:SpawnAndAttachEntity( blueprint, self.entity, "att_r_hand_item","")
			EntityService:SetMaterial(leftSword, "selector/hologram_blue", "default")
		end
	end
end

function holo_decoy_mech:OnDecoyStart( state )
	state:SetDurationLimit( self.explodeTime )
end

function holo_decoy_mech:OnDecoyEnd(  )
	QueueEvent("DestroyRequest", self.entity, "default", 100 )
end

return holo_decoy_mech
