require("lua/utils/table_utils.lua")

class 'logic_block_players_action_mappers' ( LuaGraphNode )

function logic_block_players_action_mappers:__init()
    LuaGraphNode.__init(self, self)
end

function logic_block_players_action_mappers:init()
    self.block = self.data:GetIntOrDefault("block", 0);
end

function logic_block_players_action_mappers:Activated()
    local mechs = PlayerService:GetPlayersMechs()
    for mech in Iter(mechs ) do
	    QueueEvent( "OperateActionMapperRequest", mech, MECH_ACTION_MAPPER_NAME, self.block ~= 1 )
	    QueueEvent( "OperateActionMapperRequest", mech, BUILD_MODE_ACTION_MAPPER_NAME, self.block ~= 1 )
    end
	self:SetFinished()
end

return logic_block_players_action_mappers