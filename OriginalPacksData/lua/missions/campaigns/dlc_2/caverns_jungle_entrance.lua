require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_caverns_jungle_entrance' ( mission_base )

function mission_caverns_jungle_entrance:__init()
    mission_base.__init(self,self)
end

function mission_caverns_jungle_entrance:init()
    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_2/caverns_jungle_entrance.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_2/dom_caverns_jungle_entrance_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_caverns_jungle_entrance