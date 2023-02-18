local building_base = require("lua/buildings/building_base.lua");
require("lua/utils/reflection.lua")

class 'alien_building_with_pipe_entrance_morphium' ( building_base )

function alien_building_with_pipe_entrance_morphium:__init()
	building_base.__init(self)
end

function alien_building_with_pipe_entrance_morphium:init()
	building_base.init(self)	
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self.createInfluence = false
	BuildingService:DisableBuilding( self.entity )
end

function alien_building_with_pipe_entrance_morphium:OnBuild()
end

function alien_building_with_pipe_entrance_morphium:OnDeactivate()
	EntityService:RemoveComponent(self.entity, "InfluenceComponent")
end

function alien_building_with_pipe_entrance_morphium:OnActivate()
	if ( self.createInfluence == true ) then
		self:CreateInfluence()
	end
end

function alien_building_with_pipe_entrance_morphium:CreateInfluence()
	local influenceComponent = EntityService:CreateComponent(self.entity, "InfluenceComponent")
	local influenceComponentHelper = reflection_helper(influenceComponent)
	influenceComponentHelper.radius = 10
	influenceComponentHelper.energy_radius = 0
	influenceComponentHelper.emissive_radius = 5
	influenceComponentHelper.creation_time_step = 0.8
end

function alien_building_with_pipe_entrance_morphium:OnLuaGlobalEvent( event )
	if "AlienBuildingScannedEvent" == event:GetEvent() then
		BuildingService:EnableBuilding( self.entity )
	elseif "InfluenceDeployFromAlienBuildingRequest" == event:GetEvent() then
		self.createInfluence = true
		if ( self.working ) then
			self:CreateInfluence()
		end
	end
end

return alien_building_with_pipe_entrance_morphium