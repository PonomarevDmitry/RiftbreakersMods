require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_metallic_factory' ( mission_base )

function mission_metallic_factory:__init()
    mission_base.__init(self,self)
end

function mission_metallic_factory:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_1/metallic_factory.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_1/dom_metallic_factory_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_metallic_factory