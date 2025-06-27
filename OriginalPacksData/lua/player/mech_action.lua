class 'mech_emote' ( LuaEntityObject )

function mech_emote:__init()
	LuaEntityObject.__init(self,self)
end

function mech_emote:init()
	local parent = EntityService:GetParent(self.entity)

	if self.data:HasString("play_animation") then
		QueueEvent("StunWithPoseEvent", parent, EntityService:GetLifeTime( self.entity ), self.data:GetString("play_animation") )
	end

	if self.data:HasString("send_chat_message") then
		QueueEvent("PlayerChatRequest", parent, self.data:GetString("send_chat_message"), 4)
	end

	if self.data:HasString("spawn_blueprint") then
		EntityService:SpawnEntity(self.data:GetString("spawn_blueprint"), self.entity, "" )
	end
end

return mech_emote