require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_survival = require("lua/missions/mission_base.lua")
class 'mission_prologue' ( mission_survival )

function mission_prologue:__init()
    mission_survival.__init(self,self)
end

function mission_prologue:PrepareSpawnPoints()
    local spawn_point = MapGenerator:SelectSpawnPoint();
    if not Assert( spawn_point ~= INVALID_ID, "Failed to select spawn point!") then
        return
    end

    MapGenerator:SetInitialSpawnPoint( spawn_point );

    --self:RemoveSpawnersAroundSpawnPoint( spawn_point, 128.0 );
    self:SelectWaveSpawnPoints();

    return spawn_point
end

function mission_prologue:init()
    self:PrepareSpawnPoints();
	local prologueStartPoint = ConsoleService:GetConfig( "start_point" )
	LogService:Log("CONSOLE VAR LOG: " .. prologueStartPoint )
	if prologueStartPoint == "" then
		prologueStartPoint = "default"
	end
	MissionService:ActivateMissionFlow("", "logic/missions/campaigns/prologue/default.logic", prologueStartPoint )
	
    local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/prologue/v2/dom_prologue_rules_" )
    MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end

return mission_prologue
