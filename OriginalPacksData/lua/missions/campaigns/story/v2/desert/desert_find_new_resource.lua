require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_desert_find_new_resource' ( mission_base )

function mission_desert_find_new_resource:__init()
    mission_base.__init(self,self)
end

function mission_desert_find_new_resource:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/desert_find_new_resource.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/desert/dom_desert_find_new_resource_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_desert_find_new_resource