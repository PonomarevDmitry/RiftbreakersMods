require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'repair_facility_drone' ( drone_spawner_building )

function repair_facility_drone:__init()
	drone_spawner_building.__init(self,self)
end

function repair_facility_drone:OnInit()
	drone_spawner_building.OnInit( self )
	
	self.energy_cost = self.data:GetFloatOrDefault("energy_cost", 20)

	self.nearby_drones = 0
	self.working_drones = 0
end

function repair_facility_drone:UpdateWorkingDrones(drone_enabled)
	if drone_enabled then
		self.working_drones = self.working_drones + 1

		if self.working_drones == 1 then
			BuildingService:AddConverterCostModifier( self.entity, self.energy_cost, "drones" )
		end
	else
		self.working_drones = self.working_drones - 1

		if self.working_drones == 0 then
			BuildingService:RemoveConverterCostModifier( self.entity, "drones" )
		end
	end
end

function repair_facility_drone:OnDroneLiftingStarted(drone)
	self:UpdateWorkingDrones(true)

    --EntityService:FadeEntity( drone, DD_FADE_IN, 0.5 )
end

function repair_facility_drone:OnDroneLandingStarted(drone)
	self:UpdateWorkingDrones(false)

    --QueueEvent( "FadeEntityOutRequest", drone, 2.0 )
end

return repair_facility_drone
