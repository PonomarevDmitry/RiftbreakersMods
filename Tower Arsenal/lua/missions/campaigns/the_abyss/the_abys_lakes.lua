require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_the_abys_lakes' ( mission_base )

function mission_the_abys_lakes:__init()
    mission_base.__init(self,self)
end

function mission_the_abys_lakes:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/the_abyss/the_abys_lakes.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/the_abyss/dom_the_abys_lakes_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_the_abys_lakes