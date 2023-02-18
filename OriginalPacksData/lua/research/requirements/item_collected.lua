class 'item_collected' ( LuaGraphNode )

function item_collected:__init()
    LuaGraphNode.__init(self,self)
end

function item_collected:init()
	self.item_count     = self.data:GetIntOrDefault( "item_count", 1 )
	self.item_blueprint = self.data:GetString( "item_blueprint" )
end

function item_collected:IsReadyForResearch()
	return PlayerService:GetItemNumber( 0, self.item_blueprint ) >= self.item_count;
end

function item_collected:OnResearchAcquired()
end

return item_collected