class 'day_cycle_machine' ( LuaEntityObject )

function day_cycle_machine:__init()
	LuaEntityObject.__init(self, self)
end

function day_cycle_machine:EnableTimeStateMachine()
	if self._dayCycleFSM then return end

	self.sunset_night_sunrise = false

	self:RegisterHandler( event_sink , "DayStartedEvent", "_OnDayCycleDayStartedEvent")	
	self:RegisterHandler( event_sink , "NightStartedEvent", "_OnDayCycleNightStartedEvent")	
	self:RegisterHandler( event_sink , "SunriseStartedEvent", "_OnDayCycleSunriseStartedEvent")	
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "_OnDayCycleSunsetStartedEvent")	

	self:_CreateDayStateMachine()
	local timeOfDay = EnvironmentService:GetTimeOfDay()
	self:_ChangeDayState(timeOfDay)
end

function day_cycle_machine:_CreateDayStateMachine()
	self._dayCycleFSM = {
		current_state = "",
		day = { enter="_OnDayEnter", exit="_OnDayExit" },
		night = { enter="_OnNightEnter", exit="_OnNightExit" },
		sunrise = { enter="_OnSunriseEnter", exit="_OnSunriseExit" },
		sunset = { enter="_OnSunsetEnter", exit="_OnSunsetExit" },
	}
end

function  day_cycle_machine:_ChangeDayState( stateName )
	local currentState = self._dayCycleFSM.current_state 
	if ( currentState == stateName ) then
		return
	end
	if ( currentState ~= "") then
		local functionCallback = self._dayCycleFSM[currentState]
		self[functionCallback.exit](self)
	end

	self._dayCycleFSM.current_state = stateName

	if ( stateName ~= "" ) then
		local functionCallback = self._dayCycleFSM[stateName]
		self[functionCallback.enter](self)
	end

end

function day_cycle_machine:DisableTimeStateMachine()
	if not self._dayCycleFSM then return end

	self:UnregisterHandler( event_sink, "DayStartedEvent", "_OnDayCycleDayStartedEvent")	
	self:UnregisterHandler( event_sink, "NightStartedEvent", "_OnDayCycleNightStartedEvent")	
	self:UnregisterHandler( event_sink, "SunriseStartedEvent", "_OnDayCycleSunriseStartedEvent")	
	self:UnregisterHandler( event_sink, "SunsetStartedEvent", "_OnDayCycleSunsetStartedEvent")	
	
	self._dayCycleFSM = nil
end

function day_cycle_machine:_OnDayEnter( state )
	if ( self.sunset_night_sunrise == true ) then
		EffectService:DestroyEffectsByGroup(self.entity, "sunset_night_sunrise")
		self.sunset_night_sunrise = false
	end
	
	EffectService:AttachEffects(self.entity, "day")
end

function day_cycle_machine:_OnDayExit( state )
	EffectService:DestroyEffectsByGroup(self.entity, "day")
end

function day_cycle_machine:_OnNightEnter( state )
	if( self.sunset_night_sunrise == false ) then
		EffectService:AttachEffects(self.entity, "sunset_night_sunrise")
		self.sunset_night_sunrise = true
	end
	EffectService:AttachEffects(self.entity, "night")
end

function day_cycle_machine:_OnNightExit( state )
	EffectService:DestroyEffectsByGroup(self.entity, "night")
end

function day_cycle_machine:_OnSunriseEnter( state )
	if( self.sunset_night_sunrise == false ) then
		EffectService:AttachEffects(self.entity, "sunset_night_sunrise")
		self.sunset_night_sunrise = true
	end
	EffectService:AttachEffects(self.entity, "sunrise")
end

function day_cycle_machine:_OnSunriseExit( state )
	EffectService:DestroyEffectsByGroup(self.entity, "sunrise")
	if ( self.sunset_night_sunrise == true ) then
		local delay = RandFloat( 0.0, 5.0 )
		EffectService:DestroyDelayedEffectsByGroup(self.entity, "sunset_night_sunrise", delay)
		self.sunset_night_sunrise = false
	end
end

function day_cycle_machine:_OnSunsetEnter( state )
	if( self.sunset_night_sunrise == false ) then
		EffectService:AttachEffects(self.entity, "sunset_night_sunrise")
		self.sunset_night_sunrise = true
	end
	EffectService:AttachEffects(self.entity, "sunset")
end

function day_cycle_machine:_OnSunsetExit( state )
	EffectService:DestroyEffectsByGroup(self.entity, "sunset")
end

function day_cycle_machine:_OnDayCycleDayStartedEvent( )
	self:_ChangeDayState("day")
end

function day_cycle_machine:_OnDayCycleNightStartedEvent( )
	self:_ChangeDayState("night")
end

function day_cycle_machine:_OnDayCycleSunriseStartedEvent( )
	self:_ChangeDayState("sunrise")
end

function day_cycle_machine:_OnDayCycleSunsetStartedEvent( )
	self:_ChangeDayState("sunset")
end

function day_cycle_machine:OnLoad()
	if ( not self._dayCycleFSM ) then
		return
	end
	if ( type(self._dayCycleFSM) ~= "table" ) then
		local currentState = self._dayCycleFSM:GetCurrentState()
		self:DestroyStateMachine(self._dayCycleFSM)
		self:_CreateDayStateMachine()
		self:_ChangeDayState(currentState)
	end

end

return day_cycle_machine