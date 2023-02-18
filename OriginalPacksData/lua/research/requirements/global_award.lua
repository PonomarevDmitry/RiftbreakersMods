class 'global_award' ( LuaGraphNode )

function global_award:__init()
    LuaGraphNode.__init(self,self)
end

function global_award:init()
	self.item_blueprint = self.data:GetString( "item_blueprint" )
end

function global_award:IsReadyForResearch()
	return PlayerService:HasGlobalAward( self.item_blueprint );
end

function global_award:OnResearchAcquired()
end

return global_award