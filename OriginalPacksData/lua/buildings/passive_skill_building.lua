local building_base = require("lua/buildings/building_base.lua")

class 'passive_skill_building' ( building_base )

function passive_skill_building:__init()
	building_base.__init(self,self)
end

function passive_skill_building:OnInit()

end

function passive_skill_building:OnActivate()
	QueueEvent( "AddPassiveSkillRequest", self.entity, self.data:GetString("name"), self.data:GetInt("owner")  )
end

function passive_skill_building:OnDeactivate()
	QueueEvent( "RemovePassiveSkillRequest", self.entity, self.data:GetString("name"), self.data:GetInt("owner") )
end

return passive_skill_building
