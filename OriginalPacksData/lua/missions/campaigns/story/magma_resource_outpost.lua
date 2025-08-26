require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_magma_resource_outpost' ( mission_base )

function mission_magma_resource_outpost:__init()
    mission_base.__init(self,self)
end

function mission_magma_resource_outpost:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/magma_resource_outpost.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/magma/dom_magma_resource_outpost_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_magma_resource_outpost