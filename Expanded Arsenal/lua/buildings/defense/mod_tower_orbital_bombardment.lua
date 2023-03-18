local building = require("lua/buildings/building.lua")

class 'tower_orbital_bombardment' ( building )

function tower_orbital_bombardment:__init()
	building.__init(self,self)
end

function tower_orbital_bombardment:OnInit()
	self:RegisterHandler( event_sink , "DayStartedEvent", "_OnDayCycleDayStartedEvent")	
	self:RegisterHandler( event_sink , "NightStartedEvent", "_OnDayCycleNightStartedEvent")	
	self:RegisterHandler( event_sink , "SunriseStartedEvent", "_OnDayCycleSunriseStartedEvent")	
	self:RegisterHandler( event_sink , "SunsetStartedEvent", "_OnDayCycleSunsetStartedEvent")	
	self:RegisterHandler( self.entity, "ResourceMissingEvent", "OnResourceMissingEvent" ) 
	self:RegisterHandler( self.entity, "TurretEvent", "OnTurretEvent" )
	self.lightStatus = false
	
	self.data:SetFloat( "shooting", 0 )
	local timeOfDay = EnvironmentService:GetTimeOfDay()

	self.range = self.data:GetFloatOrDefault("range", 35 )
	self.reload = self.data:GetIntOrDefault("reload", 10 )
	self.weapon = self.data:GetStringOrDefault("bombardment", "items/skills/orbital_bombardment_advanced")
	self.marker = self.data:GetStringOrDefault("marker", "effects/enemies_gnerot/spike_warning")

	self.fsm = self:CreateStateMachine();
	self.fsm:AddState( "SRQModCheck", { execute="OnSRQModCheck" });
	self.fsm:AddState( "SRQModIdle", { execute="OnSRQModIdle" });
    self.fsm:AddState( "SRQModShoot", { execute="OnSRQModShoot" });
	self.fsm:AddState( "SRQModReload", { enter="SRQModReloadEnter", exit="SRQModReloadExit" });

end

function tower_orbital_bombardment:OnSRQModCheck( state ) -- check function to stop shooting if the conditions are not satisfied.
	if not (BuildingService:IsBuildingPowered( self.entity )) then
		self.fsm:ChangeState("SRQModIdle")
	elseif not (BuildingService:IsResourceSupplied( self.entity )) then
		self.fsm:ChangeState("SRQModIdle")
	elseif not (BuildingService:IsWorking( self.entity )) then
		self.fsm:ChangeState("SRQModIdle")
	else
		self.fsm:ChangeState("SRQModShoot")
	end
end

function tower_orbital_bombardment:OnSRQModIdle( state ) -- loop function back to check function.
	self.fsm:ChangeState("SRQModCheck")
end

function tower_orbital_bombardment:OnSRQModShoot( state )

	local l_player = PlayerService:GetPlayerControlledEnt( 0 )
	local predicate = {
		signature = "TeamComponent",
		type="ground_unit",
		filter = function(entity)
			return EntityService:IsInTeamRelation(l_player, entity, "hostility")
		end
	};

	local entities = FindService:FindEntitiesByPredicateInRadius( self.entity, self.range, predicate );
	local target = FindClosestEntity( self.entity, entities );
	if target == INVALID_ID then
		return
	end

	local l_target_position = EntityService:GetPosition(target)

	EntityService:SpawnEntity( self.marker, l_target_position, EntityService:GetTeam( self.entity ) )
	l_target_position.y = 30
	self.laser = EntityService:SpawnEntity( self.weapon, l_target_position, EntityService:GetTeam( self.entity ) )
	
	WeaponService:UpdateWeaponStatComponent( self.laser, self.laser )
	WeaponService:StartShoot( self.laser )
	self.fsm:ChangeState("SRQModReload")
end

function tower_orbital_bombardment:SRQModReloadEnter( state )
	BuildingService:AttachGuiTimer( self.entity, self.reload, true )   
	state:SetDurationLimit( self.reload ) 
end

function tower_orbital_bombardment:SRQModReloadExit( state )
	self.fsm:ChangeState("SRQModCheck")
end


function tower_orbital_bombardment:OnDestroy()
	return true
end

function tower_orbital_bombardment:_OnDayCycleDayStartedEvent( )
	self:OperateLight("day")
end

function tower_orbital_bombardment:_OnDayCycleNightStartedEvent( )
	self:OperateLight("night")
end

function tower_orbital_bombardment:_OnDayCycleSunriseStartedEvent( )
	self:OperateLight("sunrise")
end

function tower_orbital_bombardment:_OnDayCycleSunsetStartedEvent( )
	self:OperateLight("sunset")
end

function tower_orbital_bombardment:OnActivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.fsm:ChangeState("SRQModCheck")
end

function tower_orbital_bombardment:OnDeactivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.fsm:ChangeState("SRQModCheck")
end

function tower_orbital_bombardment:OnTurretEvent( evt )
end

function tower_orbital_bombardment:OperateLight( time )
	if self.working == true and time ~= "day" and self.lightStatus == false then
		EffectService:AttachEffects(self.entity, "lamp")	
		self.lightStatus = true
	elseif self.working == false and self.lightStatus == true then 
		EffectService:DestroyEffectsByGroup(self.entity, "lamp")	
		self.lightStatus = false
	elseif time == "day" and self.lightStatus == true then
		EffectService:DestroyEffectsByGroup(self.entity, "lamp")	
		self.lightStatus = false
	end
end


function tower_orbital_bombardment:OnResourceMissingEvent( evt )
	local resource = evt:GetResource()
	if ( resource ~= "energy" and resource ~= "ai" and ConsoleService:GetConfig("g_tower_ammo_missing_annoucements") == "1" ) then
		EntityService:ShowTimeoutSoundEvent( INVALID_ID, 30.0, "voice_over/announcement/not_enough_ammo_tower", false )
	end
end

return tower_orbital_bombardment