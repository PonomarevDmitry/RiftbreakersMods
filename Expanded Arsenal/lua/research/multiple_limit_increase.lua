class 'multiple_limit_increase' ( LuaGraphNode )

function multiple_limit_increase:__init()
    LuaGraphNode.__init(self,self)
end

function multiple_limit_increase:init()

	Assert( self.data:HasString("limit_name"), " ERROR: no limit_name in limit_increase.lua script database!" )
	self.limitIncrease = self.data:GetIntOrDefault( "increase_amount", 1 )
	self.limitName = self.data:GetStringOrDefault("limit_name","")
end

function multiple_limit_increase:IsReadyForResearch()
	return true
end

function multiple_limit_increase:OnResearchAcquired()

	local limit_Name = Split(self.limitName, ",")
	
	for i =1, #(limit_Name) do
		BuildingService:IncreaseBuildingLimits( limit_Name[i], self.limitIncrease)
	end
end

return multiple_limit_increase