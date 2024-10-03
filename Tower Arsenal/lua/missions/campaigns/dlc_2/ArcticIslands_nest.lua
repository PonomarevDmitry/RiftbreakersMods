require("lua/utils/table_utils.lua")
require("lua/utils/rules_utils.lua")

local mission_base = require("lua/missions/mission_base.lua")
class 'mission_ArcticIslands_nest' ( mission_base )

function mission_ArcticIslands_nest:__init()
    mission_base.__init(self,self)
end

function mission_ArcticIslands_nest:SelectWaveSpawnPoints()
end

function mission_ArcticIslands_nest:init()
    
	self:PrepareSpawnPoints();
	
	MissionService:SetSkipSpawnPortalSequence(true)
    MissionService:ActivateMissionFlow("", "logic/missions/campaigns/dlc_2/ArcticIslands_nest.logic", "default" )

    self.cavernsVersion = 1
    
	self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
	self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    --local rulesPath = GetRulesForDifficulty( "lua/missions/campaigns/dlc_2/dom_ArcticIslands_nest_rules_" )
    --MissionService:AddGameRule( "lua/missions/v2/dom_manager.lua", rulesPath )
end


function mission_ArcticIslands_nest:OnLoad()
    
    if ( self.version == nil or self.version < 1 ) then
        self:RegisterHandler( event_sink, "RespawnFailedEvent",			   "OnRespawnFailedEvent" )
        self:RegisterHandler( event_sink, "PlayerDiedEvent",			   "OnPlayerDiedEvent" )
    end
end


function mission_ArcticIslands_nest:OnRespawnFailedEvent()
	--self:VerboseLog("Mission failed" )

    LampService:ReportGameFailed()
	MissionService:ShowEndGameHud( 5.0, false )
	local failedAction = MissionService:GetCurrentMissionFailedAction();
	if ( failedAction ~= MFA_REMAIN ) then
		MissionService:DeactivateAllFlows()
	end
end


function mission_ArcticIslands_nest:DestroyPlayerItems( owner, player )
	local count = DifficultyService:GetNumberOfItemsRemovedOnDeath();

	if ( count == 0 ) then
		return
	end
	local status = CampaignService:GetMissionStatus( CampaignService:GetCurrentMissionId() )
	if ( status ~= MISSION_STATUS_IN_PROGRESS and status ~= MISSION_STATUS_NONE ) then
		return
	end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND", player )
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND", player ) )   
	count = math.min( count, #items )

	local name = ""
	local lvl = ""
	for i=1,count,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		EntityService:RemoveEntity( entity)
	end

end

function mission_ArcticIslands_nest:DropPlayerItems( owner, player )
	local dropItemsCount = DifficultyService:GetNumberOfItemsDroppedOnDeath();
	if ( dropItemsCount == 0 ) then
		return
	end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND" , player)
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND", player ) )   
	dropItemsCount = math.min( dropItemsCount, #items )

	local dropped = {}
	local name = ""
	local lvl = ""
	for i=1,dropItemsCount,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Insert(dropped, entity )
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		PlayerService:DropItem( entity, owner, owner )
	end

	if dropItemsCount >= (#items + #dropped) then
		CampaignService:UnlockAchievement(ACHIEVEMENT_LEAVING_EMPTY_HANDED);
	end
end

function mission_ArcticIslands_nest:OnPlayerDiedEvent( evt )
	self:DestroyPlayerItems(evt:GetEntity(), evt:GetPlayerId())
	self:DropPlayerItems(evt:GetEntity(), evt:GetPlayerId())
end


return mission_ArcticIslands_nest