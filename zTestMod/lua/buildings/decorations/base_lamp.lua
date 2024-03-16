local building = require("lua/buildings/building.lua")

class 'base_lamp' ( building )

function base_lamp:__init()
	building.__init(self,self)
end

function base_lamp:OnInit()

	building.OnInit( self )

	self:RegisterHandler( event_sink , "DayStartedEvent", "OnDayStartedEvent")
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "OnSunsetStartedEvent")
	
	if ( BuildingService:IsBuildingFinished( self.entity ) ) then
		self:SetWorking()
	end
end

function base_lamp:OnLoad()

	building.OnLoad( self )

	self:RegisterHandler( event_sink , "DayStartedEvent", "OnDayStartedEvent")
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "OnSunsetStartedEvent")
	
	if ( BuildingService:IsBuildingFinished( self.entity ) ) then
		self:SetWorking()
	end
end

function base_lamp:OnBuildingEnd()

	self:SetWorking()
end

function base_lamp:SetWorking()
	local timeOfDay = EnvironmentService:GetTimeOfDay()
	if ( timeOfDay == "day" or timeOfDay == "sunrise" ) then
		self.data:SetInt("is_working", 0 )
		BuildingService:DisableBuilding( self.entity )
	else
		self.data:SetInt("is_working", 1 )
		BuildingService:EnableBuilding( self.entity )
	end
end

function base_lamp:OnDayStartedEvent(evt)
	self.data:SetInt("is_working", 0 )
	BuildingService:DisableBuilding( self.entity )
end

function base_lamp:OnSunsetStartedEvent(evt)
	self.data:SetInt("is_working", 1 )
	BuildingService:EnableBuilding( self.entity )
end

function base_lamp:OnActivate()
	self.data:SetInt("is_working", 1 )
end

function base_lamp:OnDeactivate()
	self.data:SetInt("is_working", 0 )
end

return base_lamp
