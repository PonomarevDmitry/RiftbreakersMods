class 'mech_emote' ( LuaEntityObject )

function mech_emote:__init()
	LuaEntityObject.__init(self,self)
end

function mech_emote:EnsureUniqueEmote()
    local mod_group = EntityService:GetGroup(self.entity)
    if mod_group == "" then
        return
    end

    local children = EntityService:GetChildren( self.parent, true )
    for child in Iter( children ) do
        local child_group = EntityService:GetGroup(child)
        if child_group == mod_group and child ~= self.entity then
            EntityService:RemoveEntity( child )
        end
    end
end

function mech_emote:init()
	self.parent = EntityService:GetParent(self.entity)

	self:EnsureUniqueEmote()

	if self.data:HasString("play_animation") then
		QueueEvent("StunWithPoseEvent", self.parent, EntityService:GetLifeTime( self.entity ), self.data:GetString("play_animation") )
	end

	if self.data:HasString("send_chat_message") then
		QueueEvent("PlayerChatRequest", self.parent, "<style='chat_user'>${sender:plain}:</style> ${" .. self.data:GetString("send_chat_message") .. "}", 4)
	end

	if self.data:HasString("spawn_blueprint") then
		EntityService:SpawnEntity(self.data:GetString("spawn_blueprint"), self.entity, "" )
	end
end

return mech_emote