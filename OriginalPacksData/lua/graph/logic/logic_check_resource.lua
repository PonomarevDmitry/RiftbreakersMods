class 'logic_check_resource' ( LuaGraphNode )

function logic_check_resource:__init()
    LuaGraphNode.__init(self, self)
end

function logic_check_resource:init()
end

function logic_check_resource:Update(time)
    local tempList = self.data:GetStringKeys()
    local canFinish = true
    for i = 1, #tempList do 
        self.resurceCheckValue = tonumber( self.data:GetString( tempList[i] ) )
        self.resurceHasValue   = PlayerService:GetResourceAmount( tostring( tempList[i] ) )

        --LogService:Log( "Required " .. tostring( tempList[i] ) .. " : " .. tostring( self.resurceCheckValue ) .. " has : " .. tostring( self.resurceHasValue ) )
        LogService:DebugText( 150, 150, "Required " .. tostring( tempList[i] ) .. " : " .. tostring( self.resurceCheckValue ) .. " has : " .. tostring( self.resurceHasValue ), "debug_white_size_38" )
        if ( self.resurceHasValue < self.resurceCheckValue ) then
            canFinish = false
        end
    end

    if ( canFinish == true ) then
        self:SetFinished()
    end

end

return logic_check_resource