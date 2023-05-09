class 'entity_add_resource' ( LuaGraphNode )

function entity_add_resource:__init()
    LuaGraphNode.__init(self, self)
end

function entity_add_resource:init()
end

function entity_add_resource:Activated()
    local tempList = self.data:GetStringKeys()
    --LogService:Log( tostring( #tempList ) )
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )

    for i = 1, #tempList do 
        local resourceAmount = tonumber( self.data:GetString( tempList[i] ) )
        local resourceName = tostring( tempList[i] )
        PlayerService:AddResourceAmount(playerId, resourceName, resourceAmount, false )
    end

    self:SetFinished()
end

return entity_add_resource