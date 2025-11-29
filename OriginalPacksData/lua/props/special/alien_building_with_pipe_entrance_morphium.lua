local building_base = require("lua/buildings/building_base.lua");
require("lua/utils/reflection.lua")

class 'alien_building_with_pipe_entrance_morphium' ( building_base )

function alien_building_with_pipe_entrance_morphium:__init()
	building_base.__init(self)
end

function alien_building_with_pipe_entrance_morphium:init()
	building_base.init(self)	
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	EntityService:DisableComponent(self.entity, "ResourceConverterComponent")
	self.alienVersion = 1
end

function alien_building_with_pipe_entrance_morphium:OnBuild()
end

function alien_building_with_pipe_entrance_morphium:OnDeactivate()
	EntityService:RemoveComponent(self.entity, "InfluenceComponent")
end

function alien_building_with_pipe_entrance_morphium:OnActivate()
	if ( EntityService:GetComponent(self.entity, "ResourceConverterComponent") == nil ) then
		return
	end

	if ( EntityService:GetComponent(self.entity, "InfluenceComponent") == nil ) then
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
		EntityService:EnableComponent(self.entity, "ResourceConverterComponent")
	elseif "InfluenceDeployFromAlienBuildingRequest" == event:GetEvent() then
		if ( self.working and EntityService:GetComponent(self.entity, "InfluenceComponent") == nil ) then
			self:CreateInfluence()
		end
	end
end


function alien_building_with_pipe_entrance_morphium:OnLoad()
	if (self.alienVersion == nil) then
		if ( not BuildingService:IsBuildingEnabled( self.entity ) ) then
			BuildingService:EnableBuilding( self.entity )
			EntityService:DisableComponent(self.entity, "ResourceConverterComponent")
		end
		self.alienVersion = 1
	end
	

end

return alien_building_with_pipe_entrance_morphium