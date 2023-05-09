local building = require("lua/buildings/building.lua")

class 'base_lamp' ( building )

function base_lamp:__init()
	building.__init(self,self)
end

function base_lamp:OnInit()
	self:RegisterHandler( event_sink , "DayStartedEvent", "OnDayStartedEvent")
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "OnSunsetStartedEvent")
end

function base_lamp:OnBuildingEnd()
	local timeOfDay = EnvironmentService:GetTimeOfDay()
	if ( timeOfDay == "day" or timeOfDay == "sunrise" ) then
		BuildingService:DisableBuilding( self.entity )
		self.data:SetInt("is_working", 0 )
	else
		BuildingService:EnableBuilding( self.entity )
	end
end

function base_lamp:OnDayStartedEvent(evt)
	BuildingService:DisableBuilding( self.entity )
end

function base_lamp:OnSunsetStartedEvent(evt)
	BuildingService:EnableBuilding( self.entity )
end

function base_lamp:OnActivate()
	self.data:SetInt("is_working", 1 )
end

function base_lamp:OnDeactivate()
	self.data:SetInt("is_working", 0 )
end


return base_lamp
