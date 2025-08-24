require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_swamp_thicket' ( mission_base )

function mission_swamp_thicket:__init()
    mission_base.__init(self,self)
end

function mission_swamp_thicket:init()
    mission_base.init( self )

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_3/swamp_thicket.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_3/dom_swamp_thicket_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_swamp_thicket