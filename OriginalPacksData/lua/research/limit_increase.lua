class 'limit_increase' ( LuaGraphNode )

function limit_increase:__init()
    LuaGraphNode.__init(self,self)
end

function limit_increase:init()
	Assert( self.data:HasString("limit_name"), " ERROR: no limit_name in limit_increase.lua script database!" )
	self.limitName = self.data:GetStringOrDefault("limit_name","")
	self.limitIncrease = self.data:GetIntOrDefault( "increase_amount", 1 )
end

function limit_increase:IsReadyForResearch()
	return true
end

function limit_increase:OnResearchAcquired()
    BuildingService:IncreaseBuildingLimits( self.limitName, self.limitIncrease)
end

return limit_increase