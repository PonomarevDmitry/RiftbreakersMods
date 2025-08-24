require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_caverns_tunnel' ( mission_base )

function mission_caverns_tunnel:__init()
    mission_base.__init(self,self)
end

function mission_caverns_tunnel:init()
    mission_base.init(self)

    self:PrepareSpawnPoints();

	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_2/caverns_tunnel.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_2/dom_caverns_tunnel_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_caverns_tunnel