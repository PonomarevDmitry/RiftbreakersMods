local building = require("lua/buildings/building.lua")

class 'energy_connector' ( building )

function energy_connector:__init()
	building.__init(self,self)
end

function energy_connector:OnInit()

    building.OnInit(self)
    
	ItemService:SetInvisible( self.entity, true )
end

function energy_connector:OnDestroy()

    building.OnDestroy(self)

	return true
end

return energy_connector
