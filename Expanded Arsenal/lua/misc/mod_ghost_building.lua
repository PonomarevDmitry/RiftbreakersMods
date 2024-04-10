local ghost_building = require("lua/misc/ghost_building.lua")

class 'mod_ghost_building' ( ghost_building )

function mod_ghost_building:__init()
    ghost.__init(self,self)
end

function mod_ghost_building:OnInit()
    local tower_scale = self.data:GetFloatOrDefault("tower_scale", 0.65)
	EntityService:SetScale( self.entity, tower_scale, tower_scale, tower_scale )
end

return mod_ghost_building
 