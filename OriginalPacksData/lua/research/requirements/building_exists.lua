class 'building_exists' ( LuaGraphNode )

function building_exists:__init()
    LuaGraphNode.__init(self,self)
end

function building_exists:init()
	self.building_blueprint = self.data:GetString( "building_blueprint" )
end

function building_exists:IsReadyForResearch()
	return BuildingService:HasBuildingWithBp(self.building_blueprint)
end

function building_exists:OnResearchAcquired()
end

return building_exists