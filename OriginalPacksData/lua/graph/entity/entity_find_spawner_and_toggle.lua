require("lua/utils/find_utils.lua")
local finder_base = require("lua/graph/utils/utils_finder.lua");

class 'entity_find_spawner_and_toggle' ( finder_base )

function entity_find_spawner_and_toggle:__init()
    finder_base.__init(self, self)
end

function entity_find_spawner_and_toggle:init()
    finder_base.init(self)
    self.enable = self.data:GetStringOrDefault("state", "true" ) == "true"
end

function entity_find_spawner_and_toggle:Update()
    finder_base.Update(self)
    if ( self.enable == true ) then
        for ent in Iter(self.foundEntities) do	
            UnitSpawnerService:EnableUnitSpawner( ent )										
        end
    else
        for ent in Iter(self.foundEntities) do
            UnitSpawnerService:DisableUnitSpawner( ent )										
        end
    end
    self:SetFinished("true")
end

return entity_find_spawner_and_toggle