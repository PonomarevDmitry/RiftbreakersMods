require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_swamp_forest_cave' ( mission_base )

function mission_swamp_forest_cave:__init()
    mission_base.__init(self,self)
end

function mission_swamp_forest_cave:init()
    mission_base.init( self )
    
    self:PrepareSpawnPoints();
	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_3/swamp_forest_cave.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_3/dom_swamp_forest_cave_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_swamp_forest_cave