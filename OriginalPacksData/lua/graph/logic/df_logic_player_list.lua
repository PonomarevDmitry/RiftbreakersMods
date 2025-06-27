require("lua/utils/find_utils.lua")
require("lua/utils/data_flow.lua")

class 'df_player_list' ( LuaGraphNode )

function df_player_list:__init()
    LuaGraphNode.__init(self, self)
end

function df_player_list:Activated()
 	local players = PlayerService:GetConnectedPlayers()

    local out_players = GetEntitiesAsString(players)
    self.data:SetString("out_players", out_players)
	--LogService:Log("PLAYERS FOUND " .. #players)

    self:SetFinished()
end

return df_player_list