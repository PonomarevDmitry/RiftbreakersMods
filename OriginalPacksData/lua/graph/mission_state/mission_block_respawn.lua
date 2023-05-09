require ( "lua/utils/enumerables.lua" )
class 'mission_block_respawn' ( LuaGraphNode )

function mission_block_respawn:__init()
	LuaGraphNode.__init(self,self)
end

function mission_block_respawn:init()

end

function mission_block_respawn:Activated()   
	local blockRespawn = self.data:GetIntOrDefault("status", 1 ) == 1
	MissionService:SetBlockPlayerRespawn( blockRespawn );
	self:SetFinished();
end


return mission_block_respawn