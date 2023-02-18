local building = require("lua/buildings/building.lua")

class 'laboratory' ( building )

function laboratory:__init()
	building.__init(self,self)
end

function laboratory:OnBuildingStart()
    local enabled= PlayerService:IsResearchEnabled()
    if ( enabled == false ) then
        QueueEvent("ForceLootContainerTypeRequest", event_sink, "research")
    end
end

return laboratory
