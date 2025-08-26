require("lua/utils/find_utils.lua")
require("lua/utils/data_flow.lua")

class 'df_player_to_entity' ( LuaGraphNode )

function df_player_to_entity:__init()
    LuaGraphNode.__init(self, self)
end

function df_player_to_entity:Activated()
	local entities = {}
	if self.data:HasString("in_players") then
 		local players = GetEntitiesFromString( self.data:GetString("in_players") )
		for player in Iter( players ) do
			local playerEnt = PlayerService:GetPlayerControlledEnt( player )
			table.insert( entities, playerEnt )
		end
	end

    local out_entities = GetEntitiesAsString(entities)
    self.data:SetString("out_entities", out_entities)
	--LogService:Log("ENTITIES FOUND " .. #entities)

    self:SetFinished()
end

return df_player_to_entity