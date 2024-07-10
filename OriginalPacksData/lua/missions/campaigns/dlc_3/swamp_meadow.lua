require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_swamp_meadow' ( mission_base )

function mission_swamp_meadow:__init()
    mission_base.__init(self,self)
end

function mission_swamp_meadow:init()
	--STAGE 1
	local world_region = self:GetTileRegionBounds( { x = -3, y = -4 }, { x = 2, y = 0 } )
	--STAGE 2
    --local world_region = self:GetTileRegionBounds( { x = -3, y = -4 }, { x = 2, y = 3 } )	    
    self:SetAccessibleWorldRegion( world_region.min, world_region.max )

    self:PrepareSpawnPoints();
	MissionService:SetSkipSpawnPortalSequence(true)

    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_3/swamp_meadow.logic", "default" )

    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_3/dom_swamp_meadow_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_swamp_meadow