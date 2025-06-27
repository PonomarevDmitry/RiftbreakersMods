class 'building_exists' ( LuaGraphNode )

function building_exists:__init()
    LuaGraphNode.__init(self,self)
end

function building_exists:init()
	self.building_blueprint = self.data:GetString( "building_blueprint" )
	self.buildingBuild = false;
end

function building_exists:IsReadyForResearch()
	if ( self.buildingBuild) then
		return true;
	end
	self.buildingBuild = BuildingService:HasBuildingWithBp(self.building_blueprint)
	return self.buildingBuild
end

function building_exists:OnResearchAcquired()
end

return building_exists