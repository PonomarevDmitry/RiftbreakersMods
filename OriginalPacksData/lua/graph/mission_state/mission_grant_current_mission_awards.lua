class 'mission_grant_current_mission_awards' ( LuaGraphNode )
require("lua/utils/reflection.lua")

function mission_grant_current_mission_awards:__init()
	LuaGraphNode.__init(self,self)
end

function mission_grant_current_mission_awards:init()		
end

function mission_grant_current_mission_awards:Activated()							
    local missionDefName = CampaignService:GetCurrentMissionDefName()

    local missionDef = ResourceManager:GetResource("MissionDef", missionDefName)
    if ( missionDef == nil )then
        self.SetFinished()
        return
    end

    local missionDefHelper = reflection_helper( missionDef )
    local players = PlayerService:GetPlayersFromTeam( EntityService:GetTeam( "player") );
    for player in Iter(players) do
        PlayerService:AddItemToInventory( player, missionDefHelper.mission_award )
    end
	self:SetFinished()	
end

return mission_grant_current_mission_awards