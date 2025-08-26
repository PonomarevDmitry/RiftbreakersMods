
local base_skill = require("lua/units/skills/base_skill.lua")
class 'skill_orb' ( base_skill )

function skill_orb:__init()
	base_skill.__init(self, self)
end

function skill_orb:OnInit()
	self.orbBp			    = self.data:GetString( "orb_bp" )

	self.orbEnt = EntityService:SpawnAndAttachEntity( self.orbBp, self.entity )
	EntityService:SetTeam( self.orbEnt, EntityService:GetTeam( self.entity ) )

	local size = EntityService:GetBoundsSize( EntityService:GetParent( self.entity ) )
	local originOffset = {}

	originOffset.x = 0.0
	originOffset.y = size.y
	originOffset.z = 0.0

	EntityService:SetPosition( self.orbEnt, originOffset )

end


function skill_orb:OnUnitDeadStateEvent( evt )
	EntityService:RemoveEntity( self.entity )
end

return skill_orb