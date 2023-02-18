local building = require("lua/buildings/building.lua")

class 'solar_panels' ( building )

function solar_panels:__init()
	building.__init(self)

end

function solar_panels:OnBuildingEnd()
	local timeOfDay = EnvironmentService:GetTimeOfDay()
	if ( timeOfDay == "day" ) then
		self.timeOfDayOk = true
	else
		self.timeOfDayOk = false
	end

	self:Recalculate()
end

function solar_panels:OnInit()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", { execute="OnWorking", interval=0.2} )
	self.fsm:ChangeState( "working" )
	
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "OnSunsetStartedEvent" )
	self:RegisterHandler( event_sink , "DayStartedEvent", "OnDayStartedEvent")
	self:RegisterHandler( event_sink , "NightStartedEvent", "OnNightStartedEvent")
	self:RegisterHandler( event_sink , "RecalculateModifiersEvent", "OnRecalculateModifiersEvent")
	self.timeOfDayOk = false
	self.lastAcidDamage = 0
		
    self.cfsm = self:CreateStateMachine()
    self.cfsm:AddState( "biom_modifier", { enter="OnEnterBiomModifier", execute="OnUpdateBiomModifier" } )
end 

function solar_panels:OnDayStartedEvent(evt)
	self.timeOfDayOk = true
end

function solar_panels:OnRecalculateModifiersEvent(evt)
	self:Recalculate()
	self.cfsm:ChangeState("biom_modifier")
end

function solar_panels:OnSunsetStartedEvent(evt)
	self.timeOfDayOk = false
end

function solar_panels:OnNightStartedEvent(evt)
	self.timeOfDayOk = false
end

function solar_panels:OnActivate()
	self.data:SetInt("is_working", 1 )
end

function solar_panels:OnDeactivate()
	self.data:SetInt("is_working", 0 )
end

function solar_panels:OnDamage( evt )
	if ( evt:GetDamageType() == "acid_rain" ) then
		self.lastAcidDamage = -1.0
	end
end

function solar_panels:OnWorking( state , dt)
	local sun_yaw = EnvironmentService:GetSunLocalYaw( self.entity ) + 180.0
	self.data:SetFloat("sun_yaw", sun_yaw  )
	if ( self.lastAcidDamage < 0.0 ) then
		self.lastAcidDamage = self.lastAcidDamage + dt
	end		

	local isRaining =  not EnvironmentService:IsRaining()
	local currentWorking = self.timeOfDayOk and self.lastAcidDamage >= 0 and isRaining
	if ( currentWorking ~= self.working ) then
		self.working = currentWorking
		if (self.working) then
			BuildingService:EnableBuilding( self.entity )
		else
			BuildingService:DisableBuilding( self.entity )
		end
	end
end

function solar_panels:OnEnterBiomModifier( state )
	state:SetDurationLimit(10)
end

function solar_panels:OnUpdateBiomModifier()
	self:Recalculate()
end

function solar_panels:Recalculate()
	local modificator = BuildingService:GetSolarPowerModificator()
	BuildingService:RemoveResourceConverterEfficientyModificator( self.entity, "biome" )
	BuildingService:SetResourceConverterEfficientyModificator( self.entity, modificator, "biome" )
end

return solar_panels
