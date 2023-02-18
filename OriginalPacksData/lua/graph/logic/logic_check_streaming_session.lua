class 'logic_check_streaming_session' ( LuaGraphNodeSelector )

function logic_check_streaming_session:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_check_streaming_session:init()
end

function logic_check_streaming_session:Activated()
	
	local streamingSessionActive = GameStreamingService:IsStreamingSessionStarted()

	if ( streamingSessionActive == true ) then
		LogService:Log( "GameStreamingService:IsStreamingSessionStarted() : true " )
		self:SetFinished( "true" )
	else
		LogService:Log( "GameStreamingService:IsStreamingSessionStarted() : false " )
		self:SetFinished( "false" )
	end	
end

return logic_check_streaming_session