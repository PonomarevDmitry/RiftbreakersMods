local item = require("lua/units/ground/arachnoid_sentinel_base.lua")
require("lua/utils/table_utils.lua")

class 'arachnoid_boss' ( arachnoid_sentinel_base )

function arachnoid_boss:__init()
	arachnoid_sentinel_base.__init(self,self)
end

function arachnoid_boss:OnInit()
	--self:RegisterHandler( self.entity, "SpawnerInfoRequest",  "OnSpawnerInfoRequest" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4
	self.disallowDeathAnim = "death_3"

    self.normalExplodeProbability = 0
	self.leaveBodyProbability = 100

	EffectService:AttachEffects( self.entity, "armor" )
	self.armour = true

	local itemsString = self.data:GetStringOrDefault( "items" , "" )
	if ( itemsString ~= "" ) then
		local items = Split( itemsString, "," )
		local v = RandInt( 1, #items)
		self.item = items[v];	
		
		if ( self.item ~= nil ) then
			self.stingItem = ItemService:AddItemToInventory( self.entity, self.item )
			ItemService:EquipItemInSlot( self.entity, self.stingItem, "STING" )
		end
	end

end

function arachnoid_boss:OnAnimationMarkerReached(evt)
	if ( arachnoid_sentinel_base.OnAnimationMarkerReached ) then
		arachnoid_sentinel_base.OnAnimationMarkerReached( self, evt )
    end
	
	if ( evt:GetMarkerName() == "mrk_footstep_fl" ) then
		EffectService:AttachEffects( self.entity, "footstep_fl" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_fr" ) then
		EffectService:AttachEffects( self.entity, "footstep_fr" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_rl" ) then
		EffectService:AttachEffects( self.entity, "footstep_fl" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_rr" ) then
		EffectService:AttachEffects( self.entity, "footstep_rr" )
	end

	return true
end

function arachnoid_boss:OnDamageEvent(evt)
	if ( arachnoid_sentinel_base.OnDamageEvent ) then
		arachnoid_sentinel_base.OnDamageEvent( self, evt )
	end
	
	if self.armour ~= nil then
		if HealthService:GetHealthInPercentage( self.entity ) < 0.5 then
			EffectService:DestroyDelayedEffectsByGroup( self.entity, "armor", 2.0 )
			
			local armor_entity = EntityService:GetChildByName( self.entity, "armor")
			if armor_entity ~= INVALID_ID then
				EntityService:RequestDestroyPattern( armor_entity, "default" )
			end

			self.armour = nil
		end
	end
end

function arachnoid_boss:OnSpawnerInfoRequest( evt )
	--SoundService:PlayAnnouncement( "voice_over/announcement/warning_nest_wave_spawn", 20 ) 
end

return arachnoid_boss
