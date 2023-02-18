class 'adaptive_music_system' ( LuaGraphNode )

function adaptive_music_system:__init()
    LuaGraphNode.__init(self, self)
end

function adaptive_music_system:init()    
end

function adaptive_music_system:Activated()
	if self.data:GetString("status") == "true" then
		SoundService:EnableAdaptiveMusic( true )
		LogService:Log( "ADAPTIVE MUSIC ENABLED" )
	elseif self.data:GetString("status") == "false" then
		SoundService:EnableAdaptiveMusic( false )
		LogService:Log( "ADAPTIVE MUSIC DISABLED" )
    end
	self:SetFinished()
end

return adaptive_music_system