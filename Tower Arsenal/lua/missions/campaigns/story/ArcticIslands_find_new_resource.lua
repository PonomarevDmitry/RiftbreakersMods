require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_ArcticIslands_find_new_resource' ( mission_base )

function mission_ArcticIslands_find_new_resource:__init()
    mission_base.__init(self,self)
end

function mission_ArcticIslands_find_new_resource:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/ArcticIslands_find_new_resource.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/ArcticIslands/dom_ArcticIslands_find_new_resource_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_ArcticIslands_find_new_resource