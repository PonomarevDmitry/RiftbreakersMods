require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_survival = require("lua/missions/mission_base.lua")
class 'mission_headquarters' ( mission_survival )

function mission_headquarters:__init()
    mission_survival.__init(self,self)
end

function mission_headquarters:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/headquarters.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/headquarters/dom_headquarters_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_headquarters
