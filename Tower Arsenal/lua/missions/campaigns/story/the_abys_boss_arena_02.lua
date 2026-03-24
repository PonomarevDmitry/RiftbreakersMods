require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_the_abys_boss_arena_02' ( mission_base )

function mission_the_abys_boss_arena_02:__init()
    mission_base.__init(self,self)
end

function mission_the_abys_boss_arena_02:SelectWaveSpawnPoints()
end

function mission_the_abys_boss_arena_02:init()
    mission_base.init(self)
    
	self:PrepareSpawnPoints();
	
	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/story/the_abys_boss_arena_02.logic", "default" )

    self.cavernsVersion = 1
    
	self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
	self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    --local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/story/v2/the_abys/dom_the_abys_boss_arena_02_rules_" )
    --MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end


function mission_the_abys_boss_arena_02:OnLoad()
    mission_base.OnLoad(self)
    
    if ( self.version == nil or self.version < 1 ) then
        self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
        self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    end
end


function mission_the_abys_boss_arena_02:OnRespawnFailedEvent()
	--self:VerboseLog("Mission failed" )

    LampService:ReportGameFailed()
	MissionService:ShowEndGameHud( 5.0, false )
	local failedAction = MissionService:GetCurrentMissionFailedAction();
	if ( failedAction ~= MFA_REMAIN ) then
		MissionService:DeactivateAllFlows()
	end
end

function mission_the_abys_boss_arena_02:OnPlayerDiedEvent( evt )
	--self:DestroyPlayerItems(evt:GetEntity(), evt:GetPlayerId())
	--self:DropPlayerItems(evt:GetEntity(), evt:GetPlayerId())
end

return mission_the_abys_boss_arena_02