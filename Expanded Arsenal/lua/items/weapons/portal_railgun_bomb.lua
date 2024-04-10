local portal_bomb = require("lua/buildings/defense/tower_portal_bomb.lua")
class 'portal_railgun_bomb' ( portal_bomb )

function portal_railgun_bomb:__init()
	portal_bomb.__init(self,self)
end

function portal_railgun_bomb:init()
	local scale = self.data:GetFloatOrDefault("scale", 1)
	EntityService:SetScale( self.entity, scale, scale, scale )
	portal_bomb.init(self)
end

return portal_railgun_bomb