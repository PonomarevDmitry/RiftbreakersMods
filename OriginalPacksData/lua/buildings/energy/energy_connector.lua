local building = require("lua/buildings/building.lua")

class 'energy_connector' ( building )

function energy_connector:__init()
	building.__init(self,self)
end

function energy_connector:OnDestroy()
	return true
end

return energy_connector
