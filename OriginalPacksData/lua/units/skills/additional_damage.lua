
local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_additional_damage' ( base_skill )

function skill_additional_damage:__init()
	base_skill.__init(self, self)
end

function skill_additional_damage:OnInit()
	self:RegisterHandler( EntityService:GetParent( self.entity ), "AnimationMarkerReached", "OnAnimationMarkerReached" ) 

	self.additionalDamageBp = self.data:GetString( "additional_damage_bp" )
	self.spawnAttachment	= self.data:GetString( "spawn_attachment" )
	self.animMarker			= self.data:GetString( "anim_marker" )

end

function skill_additional_damage:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName()

	if ( markerName == self.animMarker ) then
		local parent = EntityService:GetParent( self.entity )
		EntityService:SpawnEntity( self.additionalDamageBp, parent, self.spawnAttachment, EntityService:GetTeam( parent ) )
	end

end

return skill_additional_damage