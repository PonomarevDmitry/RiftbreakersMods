class 'music_change_playlist' ( LuaGraphNode )

function music_change_playlist:__init()
    LuaGraphNode.__init(self, self)
end

function music_change_playlist:init()
end

function music_change_playlist:Activated()
    local music_list = self.data:GetString("music_list")
    SoundService:ChangePlaylist( music_list )
    self:SetFinished()
end

return music_change_playlist