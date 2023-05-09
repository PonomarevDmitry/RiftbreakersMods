class 'ears_attach_to_mech' ( LuaGraphNode )

function ears_attach_to_mech:__init()
	LuaGraphNode.__init(self, self)
end

function ears_attach_to_mech:init()
end

function ears_attach_to_mech:Activated()
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0)
	LogService:Log("Attach ears to player: " .. tostring(playerId))
	self.mech = PlayerService:GetPlayerControlledEnt(playerId)
	
	local coords = {}
	coords.x = self.data:GetIntOrDefault("coord_x",0)
	coords.y = self.data:GetIntOrDefault("coord_y",0)
	coords.z = self.data:GetIntOrDefault("coord_z",0)

	SoundService:AttachEars(self.mech,coords)

	self:SetFinished()
end

return ears_attach_to_mech