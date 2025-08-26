require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_caverns_nest' ( mission_base )

function mission_caverns_nest:__init()
    mission_base.__init(self,self)
end

function mission_caverns_nest:SelectWaveSpawnPoints()
end

function mission_caverns_nest:init()
    mission_base.init(self)
    
	self:PrepareSpawnPoints();
	
	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_2/caverns_nest.logic", "default" )

    self.cavernsVersion = 1
    
	self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
	self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    --local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_2/dom_caverns_nest_rules_" )
    --MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end


function mission_caverns_nest:OnLoad()
    mission_base.OnLoad(self)
    
    if ( self.version == nil or self.version < 1 ) then
        self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
        self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    end
end


function mission_caverns_nest:OnRespawnFailedEvent()
	--self:VerboseLog("Mission failed" )

    LampService:ReportGameFailed()
	MissionService:ShowEndGameHud( 5.0, false )
	local failedAction = MissionService:GetCurrentMissionFailedAction();
	if ( failedAction ~= MFA_REMAIN ) then
		MissionService:DeactivateAllFlows()
	end
end

function mission_caverns_nest:OnPlayerDiedEvent( evt )
	--self:DestroyPlayerItems(evt:GetEntity(), evt:GetPlayerId())
	--self:DropPlayerItems(evt:GetEntity(), evt:GetPlayerId())
end

return mission_caverns_nest