
local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_shield' ( base_skill )

function skill_shield:__init()
	base_skill.__init(self, self)
end

function skill_shield:OnInit()

	local radius = self.data:GetFloatOrDefault( "radius", 5 )

	EntityService:SetScale( self.entity, radius * 2, radius * 2, radius * 2 )
	EntityService:SetPhysicsScale( self.entity, radius, radius, radius )

end

function skill_shield:OnUnitDeadStateEvent( evt )
	EntityService:RemoveComponent( self.entity, "PhysicsComponent" )
	EntityService:DissolveEntity( self.entity, 0.3 )
end

return skill_shield