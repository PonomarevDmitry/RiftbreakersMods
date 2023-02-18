require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_acid_find_rare_resources' ( mission_base )

function mission_acid_find_rare_resources:__init()
    mission_base.__init(self,self)
end

function mission_acid_find_rare_resources:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/acid_find_rare_resource.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/acid/dom_acid_find_rare_resource_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_acid_find_rare_resources