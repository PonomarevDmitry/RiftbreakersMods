require("lua/utils/table_utils.lua")
require("lua/utils/building_utils.lua")
require ( "lua/utils/enumerables.lua" )
local building = require("lua/buildings/building.lua");

class 'rift_station' ( building )

function rift_station:__init()
	building.__init(self)
end

function rift_station:OnInit()

	self.energyNeeded 		= self.data:GetFloatOrDefault("energy_amount", 1000)
	self.resourceAmount 	= self.data:GetFloatOrDefault("resource_amount", 5000)
	self.stabilizerRadius	= self.data:GetFloatOrDefault("stabilizators_radius", 100 )
	self.activationTime		= self.data:GetFloatOrDefault("activation_time", 60 )
	self.disableTime		= self.data:GetFloatOrDefault("disable_time", 150 )
	self.fadeOutTime		= self.data:GetFloatOrDefault("fadeout_time", 1 )
	self.alienFactor		= self.data:GetIntOrDefault("alien_stablizators_factor", 2 )	
	self.stabilizerCount	= self.data:GetIntOrDefault("stabilizators_count", 4 )
	
	self:RegisterHandler( self.entity , "SpecialBuildingActionRequest", "OnSpecialAction" )
	self:RegisterHandler( event_sink, "LuaGlobalEvent", "OnLuaGlobalEvent" )
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", 	{ execute="OnWorking" } )
	self.fsm:AddState( "activated", { enter="OnPortalActivated" } )
	self.fsm:AddState( "idle",		{ execute="OnIdle", interval=0.2 } )
	self.fsm:AddState( "not_working", { enter="OnEnterWatingForWork", execute="OnIdleWaitingForWork", exit="OnExitWaitingForWork" } )
	self.fsm:AddState( "destruction", { enter="OnEnterDestruction", exit="OnExitDestruction" } )
	self.fsm:ChangeState( "idle" )
	
	self.animSm = self:CreateStateMachine()
	self.animSm:AddState("anim_idle", { execute="OnAnimation"})
	self.animSm:ChangeState( "anim_idle" )

	self.charging = 0
	self.timer = 0
	self.workingFactor = 0
	self.workingProtectionTimer = 0
	self.guiTimer = nil	
	BuildingService:DisableBuilding( self.entity )
	
	self.glowFactor = 0.0
	self.data:SetFloat( "progress", self.workingFactor * 100 )

	self.workingEffect = false
	self.portalEffect = false
	self.chargingSpeed = self.data:GetFloatOrDefault("charging_work_speed",  1.0)
	self.chargingEndSpeed = self.data:GetFloatOrDefault("charging_end_speed", 0.5)

	self.riftVersion = 3
end

function rift_station:OnBuildingEnd()
	BuildingService:DisableBuilding( self.entity )
end


function rift_station:OnSpecialAction( req )
	if( self.charging == 2 ) then
		QueueEvent( "PortalActivatedEvent", self.entity )
		self.charging = 3 
	elseif( self.charging < 0 ) then
		return
	elseif (self.charging < 2 ) then
		local child0 = EntityService:GetChildByName( self.entity, "fusion_field_accelerator")
		local child1 = EntityService:GetChildByName( self.entity, "hyper_particle_condenser")
		local child2 = EntityService:GetChildByName( self.entity, "quantum_gate_stabilizer")
		
		if ( BuildingService:IsWorking(child0) == true and BuildingService:IsWorking(child1) == true and BuildingService:IsWorking(child2) == true and BuildingService:IsResourceSupplied( self.entity ) and BuildingService:IsBuildingPowered( self.entity ) )then
			BuildingService:EnableBuilding( self.entity )
		end
	end
end

function rift_station:OnIdle( state, dt)
end

function rift_station:OnAnimation( state, dt)
	_G["rift_station_charging_state"] = self.charging
	local portalPowered = (BuildingService:IsBuildingPowered( self.entity ) or self.workingProtectionTimer > 0 ) and self.charging ~= 3
	local isWorking = (BuildingService:IsWorking( self.entity ) or self.workingProtectionTimer > 0) and self.charging ~= 3
	local specialActionEnabled = self:CanEnableSpecialAction();
	self.data:SetInt("is_special_action_enabled", specialActionEnabled and 1 or 0 )
	if (specialActionEnabled ) then
			EntityService:EnableComponent( self.entity, "InteractiveComponent")
	else
			EntityService:DisableComponent( self.entity, "InteractiveComponent")
	end

	local working 		= 0
	if ( portalPowered == true ) then
		EntityService:SetSubMeshMaterial( self.entity, "buildings/main/rift_station_base_screen", 1, "default")
		working = 1
		self.glowFactor = self.glowFactor + dt
	else
		EntityService:SetSubMeshMaterial( self.entity, "buildings/main/rift_station_base_screen_off", 1, "default")
		working = 0
		EffectService:DestroyEffectsByGroup(self.entity, "idle")
		EffectService:DestroyEffectsByGroup(self.entity, "portal_active")
		self.workingEffect = false
		self.portalEffect = false
		self.glowFactor = self.glowFactor - dt
	end
	self.glowFactor = math.min( 1.0, self.glowFactor )
	self.glowFactor = math.max( 0.0, self.glowFactor )

	self.data:SetInt("is_working", working )
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", self.glowFactor );

	if ( working > 0 ) then
		if ( isWorking ) then
			if ( self.portalEffect == false )  then
				EffectService:DestroyEffectsByGroup(self.entity, "idle")
				EffectService:AttachEffects( self.entity, "portal_active" )
				self.portalEffect = true
				self.workingEffect = false
			end	
			if ( self.charging < 2 ) then
				self.data:SetFloat("charging_speed",self.chargingSpeed )
			else
				self.data:SetFloat("charging_speed", self.chargingEndSpeed )
			end
		else
			if ( self.workingEffect == false and specialActionEnabled ) then
				EffectService:AttachEffects( self.entity, "idle" )
				self.workingEffect = true
			end	
			self.data:SetFloat("charging_speed", 0 )
		end
	else
		self.data:SetFloat("charging_speed", 0 )
	end
end

function rift_station:OnIdleWaitingForWork( state, dt)
	if ( self.guiTimer == nil ) then
		return
	end
	self.timer = self.timer + dt	
	self.timer = math.max( self.timer, 0 )	
	self.data:SetFloat( "resetting", (self.timer / self.disableTime) * 100 )
	BuildingService:SetGuiTimer( self.guiTimer, self.timer )
	self.reseting = true
end

function rift_station:OnEnterWatingForWork( state )
	QueueEvent( "LuaGlobalEvent", event_sink, "PortalResetStartEvent", {} )

	if ( self.guiTimer == nil ) then
		return
	end
	self.timer = 0.0
	self.data:SetFloat( "progress", 0.0)
	self.data:SetFloat( "resetting", 0.0)
	self.workingFactor = 0.0
	BuildingService:SetGuiTimerLimit( self.guiTimer, self.disableTime )
	BuildingService:SetGuiTimer( self.guiTimer, self.timer )
	state:SetDurationLimit( self.disableTime )
	self.reseting = true

	--BuildingService:DisableBuilding( self.entity )
end

function rift_station:OnExitWaitingForWork( state )
	self.reseting = false
	EntityService:RemoveEntity( self.guiTimer )
	self.guiTimer = nil
	self.charging = 0
	self.timer = 0
	self.data:SetFloat( "progress", 0.0)
	self.data:SetFloat( "resetting", 100 )
	self.workingFactor = 0
	BuildingService:EnableSellOption( self.entity )
	QueueEvent( "LuaGlobalEvent", event_sink, "PortalResetEndEvent", {} )
end

function rift_station:OnActivate()
	if (self.charging < 1 ) then
		QueueEvent( "OpeningPortalStartedEvent", self.entity )
		self.workingProtectionTimer = self.data:GetFloatOrDefault("protection_time", 60 )
		self.fsm:ChangeState( "working" )
		BuildingService:DecreaseEnergyAmount( self.entity, self.energyNeeded )
		self.charging = 1
		if ( self.guiTimer == nil ) then
			self.guiTimer = BuildingService:CreateGuiTimer( self.entity, self.activationTime )
		end
		BuildingService:DisableSellOption( self.entity )
	elseif ( self.charging == 1 and self.workingProtectionTimer <= 0 ) then
		self.workingProtectionTimer = self.data:GetFloatOrDefault("protection_time", 60 )
		BuildingService:ResumeGuiTimer( self.guiTimer  )
		self.fsm:ChangeState( "working" )
	end
end

function rift_station:CheckCharging()
	if (self.charging == 1 ) then
		local isWorking = true
		self.resetCounter = self.resetCounter or 0
		if ( BuildingService:IsResourceSupplied( self.entity ) == false ) then
			self.resetCounter = self.resetCounter + 1
		else
			self.resetCounter = 0
		end
		
		if (self.resetCounter > 1 ) then
			isWorking = false;
			local missingResources = BuildingService:GetMissingResources( self.entity )
			if ( IndexOf( missingResources, "water" ) ~= nil ) then
				QueueEvent( "LuaGlobalEvent", event_sink, "PortalMissingCoolantEvent", {} )
			elseif ( IndexOf( missingResources,"supercoolant" ) ~= nil ) then
				QueueEvent( "LuaGlobalEvent", event_sink, "PortalMissingCoolantEvent", {} )
			end
			if ( IndexOf( missingResources, "plasma_charged" ) ~= nil ) then
				QueueEvent( "LuaGlobalEvent", event_sink, "PortalMissingPlasmaEvent", {} )
			end
		else

		end
		
		if (BuildingService:IsBuildingPowered( self.entity ) == false ) then
			isWorking = false
			QueueEvent( "LuaGlobalEvent", event_sink, "PortalMissingPowerEvent", {} )
		end

		if ( HaveWorkingStabilizators( self.entity, self.stabilizerRadius,self.stabilizerCount, self.alienFactor) == false ) then
			isWorking = false
			QueueEvent( "LuaGlobalEvent", event_sink, "PortalMissingStabilizatorsEvent", {} )
		end
		
		if ( isWorking ) then
			return true
		else
			EffectService:AttachEffects(self.entity, "interrupt" )
			BuildingService:DisableBuilding( self.entity )
			self.charging = -1	
			if ( self.guiTimer ~= nil ) then
				BuildingService:PauseGuiTimer( self.guiTimer )
			end
			self.fsm:ChangeState( "not_working" )
			return false
		end

	end
end

function rift_station:OnPortalActivated( state)
	EffectService:DestroyEffectsByGroup(self.entity, "working")
	EffectService:AttachEffects( self.entity, "portal_opened" )
	QueueEvent( "PortalOpeningFinishedEvent", self.entity )
	
	if ( self.guiTimer ~= nil and EntityService:IsAlive(self.guiTimer ) ) then
		EntityService:RemoveEntity( self.guiTimer )
	end
	self.guiTimer = nil
	self.charging = 2 
end

function rift_station:OnLoad()
	building.OnLoad(self)
	self.workingProtectionTimer = self.workingProtectionTimer or 0.0
	if ( self.charging == 0 ) then
		BuildingService:DisableBuilding( self.entity )
	elseif (self.charging == 1 and self.workingProtectionTimer < 10 )  then
		self.workingProtectionTimer = 10
	end
	if  (self.riftVersion == nil or self.riftVersion < 1) then
		self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )
	end

	if ( self.riftVersion == nil or self.riftVersion < 2 ) then
		local blueprintDatabase = EntityService:GetBlueprintDatabase( self.entity )
		self.activationTime		= blueprintDatabase:GetFloatOrDefault("activation_time", 60 )
		self.disableTime		= blueprintDatabase:GetFloatOrDefault("disable_time", 150 )
	end

	if ( self.riftVersion == nil or self.riftVersion < 3 ) then
		EntityService:RemoveComponent( self.entity, "SoundComponent")
	end

	self.resetCounter = self.resetCounter or 0
	self.resourceAmount = self.data:GetFloatOrDefault("resource_amount", 5000)
	self.riftVersion = 3
end

function rift_station:OnWorking( state , dt)	

	if ( self.workingProtectionTimer > 0 ) then
		self.workingProtectionTimer = self.workingProtectionTimer - dt
		self.data:SetFloat("protection_timer", self.workingProtectionTimer )
	else
		local isWorking = self:CheckCharging()
		if ( isWorking == false ) then
			self:_OnDeactivate()
			return
		end
	end

	self.timer = self.timer + dt
	self.workingFactor = self.timer / self.activationTime	
	self.data:SetFloat( "progress", self.workingFactor * 100 )
	if ( self.guiTimer ~= nil ) then
		BuildingService:SetGuiTimer( self.guiTimer, self.timer )
	end
	
	if ( self.workingFactor > 1 ) then

		self.fsm:ChangeState( "activated" )
	end
end

function rift_station:CanEnableSpecialAction()
	if ( self.charging == 0 ) then
		local energyAmount = BuildingService:GetEnergyAmount( self.entity )

		if ( energyAmount < self.energyNeeded ) then	
			return false
		end
		
		if ( (BuildingService:IsResourceSupplied( self.entity ) == false) or (BuildingService:IsBuildingPowered( self.entity ) == false ) ) then
			return false 
		end
		
		local waterAmount = BuildingService:GetResourceConnected( self.entity, "water" )
		local superCoolantAmount = BuildingService:GetResourceConnected( self.entity, "supercoolant" )
		local plasmaChargedAmount = BuildingService:GetResourceConnected( self.entity, "plasma_charged" )

		if (( plasmaChargedAmount < self.resourceAmount ) or (( waterAmount + superCoolantAmount ) < self.resourceAmount )) then
			return false
		end

		if ( HaveWorkingStabilizators( self.entity, self.stabilizerRadius,self.stabilizerCount, self.alienFactor) == false ) then
			return false
		end
		local child0 = EntityService:GetChildByName( self.entity, "fusion_field_accelerator")
		local child1 = EntityService:GetChildByName( self.entity, "hyper_particle_condenser")
		local child2 = EntityService:GetChildByName( self.entity, "quantum_gate_stabilizer")
		
		if ( BuildingService:IsWorking(child0) == false or BuildingService:IsWorking(child1) == false or BuildingService:IsWorking(child2) == false)then
			return false
		end
		return true
	elseif ( self.charging == 2 ) then
		return false
	else
		return false
	end
end

function rift_station:_OnActivate()
	if ( self.workingProtectionTimer <= 0 ) then
		self.resetCounter = 0
		building._OnActivate( self )
	end
end

function rift_station:_OnDeactivate()
	if ( self.workingProtectionTimer <= 0 and self.resetCounter > 1 ) then
		building._OnDeactivate( self )
	end
end

function rift_station:PopulateSpecialActionInfo()
	self.data:SetString("stat_categories", "gui/hud/build_menu/info.activate_portal" )
	self.data:SetString("gui/hud/build_menu/info.activate_portal.icon", "")
	self.data:SetString("gui/hud/build_menu/info.activate_portal.rows", "energy,stabilizers" )
	
	self.data:SetString("gui/hud/build_menu/info.activate_portal.rows.energy.type", "resource" )
	self.data:SetFloat("gui/hud/build_menu/info.activate_portal.rows.energy.min_value", self.energyNeeded )	
	
	self.data:SetString("gui/hud/build_menu/info.activate_portal.rows.stabilizers.name", "gui/hud/building_name/rift_magnetic_stabilizer_alien" )
	self.data:SetString("gui/hud/build_menu/info.activate_portal.rows.stabilizers.icon", "gui/hud/building_icons/rift_magnetic_stabilizer_alien" )
	self.data:SetFloat("gui/hud/build_menu/info.activate_portal.rows.stabilizers.min_value", GetWorkingStabilizatorsCount( self.entity, self.stabilizerRadius, self.alienFactor ) )
	self.data:SetFloat("gui/hud/build_menu/info.activate_portal.rows.stabilizers.max_value",  self.stabilizerCount )
end

function rift_station:OnDestroy()
	local children = EntityService:GetChildren( self.entity, true )
	for child in Iter(children) do
		QueueEvent("DissolveEntityRequest", child, 1.0, 0.0 )			
	end
	if ( self.charging == 1 or self.charging == 2 or (self.reseting ~= nil and self.reseting == true ) ) then
		GuiService:FadeOutToWhite( self.fadeOutTime )
		self.charging = -1;
		self.fsm:ChangeState( "destruction" )
	else
		EntityService:DissolveEntity( self.entity, 2.0 )
	end
end

function rift_station:_OnDestroy(evt)
	local damageType = evt:GetDamageType()
	EntityService:RequestDestroyPattern( self.entity, damageType, false )
	BuildingService:DisableBuilding( self.entity ) 
	EntityService:RemoveComponent( self.entity, "PhysicsComponent" )
	EntityService:RemoveComponent( self.entity, "TeamComponent" )
end
function rift_station:OnEnterDestruction( state )
	state:SetDurationLimit( self.fadeOutTime )
	EntityService:DissolveEntity( self.entity, self.fadeOutTime )
end

function rift_station:OnExitDestruction( state )
	local missionResult = StringToMissionStatus("lose");
	MissionService:FinishCurrentMission( missionResult );
	
end
function rift_station:OnLuaGlobalEvent( event )
	if ( self.charging == 2 ) then
		if event:GetEvent() == "PortalClosedLogicEvent" then
			self.charging = 3
			BuildingService:DisableBuilding( self.entity )
			BuildingService:EnableSellOption( self.entity )
			EffectService:DestroyEffectsByGroup(self.entity, "portal_opened")
			EntityService:RemoveComponent(self.entity, "ResourceConverterComponent")
			EffectService:DestroyEffectsByGroup(self.entity, "idle")
			EffectService:DestroyEffectsByGroup(self.entity, "portal_active")
			EffectService:DestroyEffectsByGroup(self.entity, "working")
			QueueEvent("BuildingVisibleInBuildMenuRequest" , event_sink, "rift_station", false) 
		elseif (event:GetEvent() == "PortalActivatedLogicEvent" ) then
			self.charging = 3
			BuildingService:DisableBuilding( self.entity )
			EffectService:DestroyEffectsByGroup(self.entity, "portal_opened")
			EntityService:RemoveComponent(self.entity, "ResourceConverterComponent")
			EffectService:DestroyEffectsByGroup(self.entity, "idle")
			EffectService:DestroyEffectsByGroup(self.entity, "portal_active")
			EffectService:DestroyEffectsByGroup(self.entity, "working")
			EffectService:AttachEffects(self.entity, "portal_activated")	
			QueueEvent("BuildingVisibleInBuildMenuRequest" , event_sink, "rift_station", false) 
		end
	end
end

function rift_station:OnInteractWithEntityRequest( event )
    local player = PlayerService:GetPlayerByMech( event:GetOwner() )
	if ( self:CanEnableSpecialAction() ) then
	    self:OnSpecialAction()
	else
		QueueEvent("ActivateEntityRequest", self.entity, player )
	end
end

return rift_station
