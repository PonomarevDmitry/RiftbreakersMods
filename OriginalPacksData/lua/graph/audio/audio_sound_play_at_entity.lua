class 'sound_play_at_entity' ( LuaGraphNode )

function sound_play_at_entity:__init()
    LuaGraphNode.__init(self, self)
end

function sound_play_at_entity:init()
end

function sound_play_at_entity:Activated()
    self.sound_name = self.data:GetString("sound_name")
    self.entity_name = self.data:GetString("entity_name")

    SoundService:Play( self.sound_name, FindService:FindEntityByName( self.entity_name ) )
    self:SetFinished()
end

return sound_play_at_entity