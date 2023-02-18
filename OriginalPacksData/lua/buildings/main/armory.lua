local building = require("lua/buildings/building.lua")

class 'armory' ( building )

function armory:__init()
	building.__init(self,self)
end

function armory:OnBuildingStart()
    local enabled= PlayerService:IsCraftingEnabled()
    if ( enabled == false ) then
        QueueEvent("ForceLootContainerTypeRequest", event_sink, "crafting")
    end
end

return armory
