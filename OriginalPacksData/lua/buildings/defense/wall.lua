local building = require("lua/buildings/building.lua")

class 'wall' ( building )

function wall:__init()
	building.__init(self,self)
end

function wall:OnDestroy()
	return true
end

return wall
