local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_alien_defence' ( base_skill )


local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_alien_defence' ( base_skill )

function skill_alien_defence:__init()
	base_skill.__init(self, self)
end

function skill_alien_defence:OnInit()

	local radius = self.data:GetFloatOrDefault( "radius", 5 )
	self.healthChild = INVALID_ID

	EntityService:SetScale( self.entity, radius * 2, radius * 2, radius * 2 )
	EntityService:SetPhysicsScale( self.entity, radius, radius, radius )

end

function skill_alien_defence:OnUnitDeadStateEvent( evt )
	EntityService:RemoveComponent( self.entity, "PhysicsComponent" )
	EntityService:DissolveEntity( self.entity, 0.3 )
end

return skill_alien_defence