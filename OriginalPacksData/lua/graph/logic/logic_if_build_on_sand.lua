class 'logic_if_build_on_sand' ( LuaGraphNodeSelector )

function logic_if_build_on_sand:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_build_on_sand:init()

	self.version = 1
end

function logic_if_build_on_sand:Activated()		
    self:RegisterHandler( event_sink , "StartBuildingEvent", "OnStartBuildingEvent");
end

function logic_if_build_on_sand:OnStartBuildingEvent( evt )
	local buildOnSand = CampaignService:GetCampaignData():GetIntOrDefault("build_on_sand_played", 0 )  
	if ( buildOnSand == 0 ) then
		local entity = evt:GetEntity()
		local terrainType = EnvironmentService:GetTerrainTypeUnderEntity(entity)
		if ( terrainType == "quicksand" ) then
			CampaignService:GetCampaignData():SetInt("build_on_sand_played", 1 )
			self:SetFinished("true")
			self:UnregisterHandler( event_sink , "StartBuildingEvent", "OnStartBuildingEvent");
		end
	else
		self:SetFinished("false")		
	end
end

-- Deprecated start
function logic_if_build_on_sand:OnBuildingStartEvent( evt )
end
-- Deprecated end

function logic_if_build_on_sand:OnLoad( )
	
	if ( self.version == nil or self.version < 1 ) then
		self:UnregisterHandler( event_sink , "BuildingStartEvent", "OnBuildingStartEvent");
		self.version = 1
	end
end

return logic_if_build_on_sand