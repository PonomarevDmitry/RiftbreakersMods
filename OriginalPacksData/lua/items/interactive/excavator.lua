require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")
class 'excavator' ( item )

function excavator:__init()
	item.__init(self)
	self.is_active = false
end

function excavator:OnEquipped()
	if not is_server then
		return
    end
	BuildingService:DisablePhysics(self.item)
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

function excavator:OnActivate()
	if not is_server then
		return
    end
	local database = EntityService:GetDatabase( self.owner )
	if database == nil then
		return
	end

	if not self.is_active then
		self.backup = {
			item =  ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" ),
			item_type = database:GetStringOrDefault( "RIGHT_HAND_item_type", "" ),
			attack_speed  = database:GetFloatOrDefault( "right_attack_speed", 1.0 ),
		}
	end

	database:SetString("attack_name", "chainsaw_right_attack_1")
    database:SetFloat("right_attack_speed", self.data:GetFloatOrDefault("excavate_activate_speed", 1.0))
    database:SetFloat("RIGHT_HAND_use_speed", 1.0)
	database:SetString("RIGHT_HAND_item_type", "melee_weapon")

	if self.is_active then
		return
	end

	self.is_active = true
	self.is_looping = false

	--LogService:Log( "OnActivate " .. tostring( self.backup.item_type ) )



	EntityService:FadeEntityIn( self.item, 0.1 )

	if AnimationService:HasAnim(self.item, "working") then
		AnimationService:StartAnim( self.item, "working", true )
	end
	
	if self.backup.item ~= INVALID_ID then
		EntityService:FadeEntityOut( self.backup.item, 0.1 )
	end

	self:RegisterHandler(self.owner, "AnimationMarkerReached", "OnExcavatorAnimationMarkerReached")
	self:RegisterHandler(self.item, "PhysicsCollisionEvent", "OnExcavatorCollisionEvent")
end

function excavator:OnDeactivate()
	if not is_server then
		return true
    end

	self.is_active = false
	self.is_looping = false
	
	BuildingService:DisablePhysics(self.item)
	EntityService:FadeEntityOut( self.item, 0.1 )
	EffectService:DestroyEffectsByGroup( self.item, "item_active_loop" )
	AnimationService:StopAnim( self.item , "working" )

	self:UnregisterHandler(self.owner, "AnimationMarkerReached", "OnExcavatorAnimationMarkerReached")
	self:UnregisterHandler(self.item, "PhysicsCollisionEvent", "OnExcavatorCollisionEvent")

	local database = EntityService:GetDatabase( self.owner )
	if database ~= nil then
		database:SetString("attack_name", "")
		--database:SetString("last_attack_name", "")
		database:SetString("RIGHT_HAND_item_type", self.backup.item_type or "" )
		database:SetFloat("RIGHT_HAND_use_speed", 0.0 )
		database:SetFloat("right_attack_speed", self.backup.attack_speed or 1.0 )
	end
	--LogService:Log( "OnDeactivate " .. tostring( self.backup.item_type ) )

	if self.backup.item and self.backup.item ~= INVALID_ID then
		EntityService:FadeEntityIn( self.backup.item, 0.1 )
	end

	self.backup = {}
	return true
end

function excavator:OnExcavatorCollisionEvent( evt )
	if EntityService:GetComponent(evt:GetOtherEntity(), "DestructibleWallComponent") ~= nil then
		local effect = self.data:GetStringOrDefault("excavate_effect", "")
		if effect ~= "" then
			EntityService:SpawnEntity(effect, evt:GetPoint(), EntityService:GetTeam(self.owner))
		end

		ItemService:InteractWithEntity( evt:GetOtherEntity(), self.owner )
	end
end

function excavator:OnExcavatorAnimationMarkerReached( evt )
	if self.is_looping then
		return
	end
	if evt:GetMarkerName() ~= "attack_loop_start" then
		return
	end
	
	self.is_looping = true

	EffectService:AttachEffects(self.item, "item_active_loop")
	BuildingService:EnablePhysics(self.item)

	local database = EntityService:GetDatabase( self.owner )
	if database == nil then
		return
	end

	local speed = self.data:GetFloatOrDefault("excavate_swing_speed", 0.25)
    database:SetFloat("right_attack_speed", speed)
end

function excavator:DissolveShow()
end

return excavator
