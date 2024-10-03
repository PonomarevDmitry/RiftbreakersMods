local item = require("lua/units/ground/arachnoid_sentinel_base.lua")
require("lua/utils/table_utils.lua")

class 'arachnoid_boss' ( arachnoid_sentinel_base )

function arachnoid_boss:__init()
	arachnoid_sentinel_base.__init(self,self)
end

function arachnoid_boss:OnInit()
	self:RegisterHandler( self.entity, "SpawnerInfoRequest",  "OnSpawnerInfoRequest" )

	arachnoid_sentinel_base.OnInit(self)

	self.armour = EntityService:SpawnAndAttachEntity( "units/ground/arachnoid_boss_armour", self.entity, "att_armor", "" )
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
			EntityService:RequestDestroyPattern( self.armour, "default" )
			--EntityService:SetSubMeshMaterial( self.entity, "unlit/null", 1, "" )
			self.armour = nil
		end
	end
end

function arachnoid_boss:OnSpawnerInfoRequest( evt )
	SoundService:PlayAnnouncement( "voice_over/announcement/warning_nest_wave_spawn", 20 ) 
end

return arachnoid_boss
