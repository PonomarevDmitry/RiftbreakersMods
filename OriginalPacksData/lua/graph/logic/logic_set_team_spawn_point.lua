class 'logic_set_team_spawn_point' ( LuaGraphNode )

require("lua/utils/table_utils.lua")

function logic_set_team_spawn_point:__init()
    LuaGraphNode.__init(self, self)
end

function logic_set_team_spawn_point:init()	
end

function logic_set_team_spawn_point:Activated()
    local spawn_name = self.data:GetStringOrDefault( "spawn_name", "" )
    local spawn_point = FindService:FindEntityByName( spawn_name )

    local team_name = self.data:GetStringOrDefault( "team_name", "player" )

    local team = EntityService:GetTeam(team_name)
    PlayerService:SetPlayerTeamSpawnPoint( team, spawn_point )

    --local players = PlayerService:GetPlayersFromTeam(team)
    --for player in Iter(players) do
    --   PlayerService:SetTempPlayerSpawnPoint( player, INVALID_ID ) 
    --end

	self:SetFinished()
end

return logic_set_team_spawn_point