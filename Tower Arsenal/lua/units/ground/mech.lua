local day_cycle_machine = require("lua/utils/day_cycle_machine.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/teleport_machine.lua")
require("lua/utils/reflection.lua")

class 'mech' ( day_cycle_machine )

function DestroyPlayerItems( owner, player )
	local count = DifficultyService:GetNumberOfItemsRemovedOnDeath();

	if ( count == 0 ) then
		return
	end
	local status = CampaignService:GetMissionStatus( CampaignService:GetCurrentMissionId() )
	if ( status ~= MISSION_STATUS_IN_PROGRESS and status ~= MISSION_STATUS_NONE ) then
		return
	end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND", player )
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND", player ) )   
	count = math.min( count, #items )

	local name = ""
	local lvl = ""
	for i=1,count,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		EntityService:RemoveEntity( entity)
	end
end

function DropPlayerItems( owner, player )

	local dropItemsCount = DifficultyService:GetNumberOfItemsDroppedOnDeath();
	if ( dropItemsCount == 0 ) then
		return
	end

	local items = PlayerService:GetAllEquippedItemsInSlot( "LEFT_HAND" , player)
	ConcatUnique( items, PlayerService:GetAllEquippedItemsInSlot( "RIGHT_HAND", player ) )   
	dropItemsCount = math.min( dropItemsCount, #items )

	local dropped = {}
	local name = ""
	local lvl = ""
	for i=1,dropItemsCount,1 do
		local number = RandInt(1, #items)
		local entity = items[number];
		Insert(dropped, entity )
		Remove( items, entity)
		name = ItemService:GetItemName( entity )
		lvl = ItemService:GetItemLevel( entity )
		PlayerService:DropItem( entity, owner, owner )
	end

	if dropItemsCount >= (#items + #dropped) then
		CampaignService:UnlockAchievement(ACHIEVEMENT_LEAVING_EMPTY_HANDED, player );
	end

end

local function HasOtherAlivePlayersInTeam( current_player )
	local player_team = PlayerService:GetPlayerTeam( current_player )
	local players = PlayerService:GetConnectedPlayersFromTeam( player_team )
	for player_id in Iter(players) do
		local pawn = PlayerService:GetPlayerControlledEnt( player_id )
		if current_player ~= player_id and (HealthService:IsAlive( pawn ) or pawn == INVALID_ID) then
			return true
		end
	end

	return false
end

function mech:UpdateChildrenDissolveAmount( entity, type, time, checkType )
	local children =  EntityService:GetChildren( entity, false )
	for child in Iter(children) do
		local itemType = ItemService:GetItemType(child)
		if checkType == false or ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "" and itemType ~= "lift" ) then		
			EntityService:FadeEntity( child, type, time, false )
			self:UpdateChildrenDissolveAmount( child, type, time, false )
		end
	end
end

function mech:__init()
	day_cycle_machine.__init(self,self)
end

function mech:init()
	self:EnableTimeStateMachine()
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" )
	self:RegisterHandler( self.entity, "EntityKilledEvent", "OnEntityKilledEvent" )

	self:RegisterHandler( self.entity, "DamageEvent",  "OnDamageEvent" )
	self:RegisterHandler( event_sink, "RevealHiddenEntityEvent",  "OnRevealHiddenEntityEvent" )
	self:RegisterHandler( self.entity, "RiftTeleportStartEvent",  "OnRiftTeleportStartEvent" )
	self:RegisterHandler( self.entity, "EnterShadowEvent",  "OnEnterShadowEvent" )
	self:RegisterHandler( self.entity, "LeaveShadowEvent",  "OnLeaveShadowEvent" )
	
	self.invisibility = false;
	local database = EntityService:GetDatabase( self.entity )
	local isSkipPortal = MissionService:IsSkipSpawnPortalSequence()
	if ( isSkipPortal == false and database:GetIntOrDefault( "initial_spawn", 0 ) == 1 ) then
		HealthService:SetImmortality( self.entity, true )	

		self:EnableMechFunctionality( false )

		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "portal_open", {enter="OnPortalOpenEnter", execute="OnPortalOpenExecute", exit="OnPortalOpenExit"} )
		self.fsm:AddState( "initial_spawn", {enter="OnInitialSpawnEnter", execute="OnInitialSpawnExecute", exit="OnInitialSpawnExit"} )
		self.fsm:AddState( "shockwave", {enter="OnShockwaveEnter", exit="OnShockwaveExit"} )
		self.fsm:ChangeState("portal_open")
	else
		self.fsm = self:CreateStateMachine()
		self.fsm:AddState( "dissolve", {enter="OnDissolveStart", exit="OnDissolveEnd"} )
		self.fsm:ChangeState("dissolve")
	end

	self.fsm:AddState( "deactivate", {enter="OnDeactivateEnter", execute="OnDeactivateExecute", exit="OnDeactivateExit", interval=0.1} )

	self.mfsm = self:CreateStateMachine()
	self.mfsm:AddState( "update", {execute="OnUpdateExecute"} )
	self.mfsm:ChangeState( "update" )

	self.version = 1

	self.player_id = PlayerService:GetPlayerForEntity( self.entity )
	if self._OnInit then
		self:_OnInit()
	end

	if ( ConsoleService:GetConfig("debug_energy_graph_creation") == "1" ) then
		self.debugStateMachine =  self:CreateStateMachine()
		self.debugStateMachine:AddState( "creation", { execute="OnDebugEnergyGraphCreation" } )
		self.debugStateMachine:AddState( "remove", { execute="OnDebugEnergyGraphRemove" } )
		self.debugStateMachine:ChangeState("creation")
		self.debugFindRadius = 30.0
		self.debugCounter = RandInt( 50, 300 )
	end
end

function mech:OnDebugEnergyGraphCreation( state )
	if ( ConsoleService:GetConfig("debug_energy_graph_creation") == "0" ) then
		return
	end
    local spots = FindService:FindEmptySpotsInRadius(self.entity, 0, self.debugFindRadius, "", "");
	LogService:Log("spots: " .. tostring(#spots ))
	if (#spots == 0 ) then
		self.debugStateMachine:ChangeState("remove")
		return
	end 
	if ( self.debugCounter == 0 ) then
		self.debugCounter = RandInt( 50, 300 )
		self.debugStateMachine:ChangeState("remove")
		return
	end
	self.debugCounter = self.debugCounter - 1
	local index = RandInt(1, #spots)
	local transform = EntityService:GetWorldTransform(self.entity)
	transform.scale = {x=1,y=1,z=1}
	transform.orientation = {x=0,y=0,z=0,w=1}
	transform.position = spots[index]
	
	LogService:Log("Build: " .. tostring(transform.position.x) .. " " .. tostring(transform.position.y) .. " " .. tostring(transform.position.z) )
    QueueEvent("BuildBuildingRequest", INVALID_ID,self.player_id, "buildings/energy/energy_connector", transform, true, {} )
end

function mech:OnDebugEnergyGraphRemove( state )
	if ( ConsoleService:GetConfig("debug_energy_graph_creation") == "0" ) then
		return
	end

	local entities = FindService:FindEntitiesByBlueprintInRadius( self.entity,"buildings/energy/energy_connector", self.debugFindRadius )
	LogService:Log("entities: " .. tostring(#entities ))
	if (#entities < 10 ) then
		self.debugStateMachine:ChangeState("creation")
		return
	end
	if ( self.debugCounter == 0 ) then
		self.debugCounter = RandInt( 50, 300 )
		self.debugStateMachine:ChangeState("creation")
		return
	end
	self.debugCounter = self.debugCounter - 1
	local index = RandInt(1, #entities)

	local entity = entities[index]

	local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent")
	LogService:Log("Remove: " .. tostring(buildingComponent) )
    if ( buildingComponent == nil ) then
        return
    end
	
    local buildingComponentHelper = reflection_helper(buildingComponent)
	LogService:Log("Remove: " .. tostring(buildingComponentHelper.m_isSellable) )
    if ( buildingComponentHelper.m_isSellable == true ) then
		QueueEvent("SellBuildingRequest", entity, 0, false )
	end

	-- body
end

function mech:OnRiftTeleportStartEvent()
    local playerId = PlayerService:GetPlayerForEntity(self.entity )
	PlayerService:SetPadHapticFeedback(playerId, "sound/samples/haptic/interactive_teleport.wav", false, 5 )
end

function mech:OnEnterShadowEvent()
	EnvironmentService:SetResistance( self.entity, "sunburn", 0.0, "shadow")
end

function mech:OnLeaveShadowEvent()
	EnvironmentService:RemoveResistance( self.entity, "sunburn", "shadow")
end

function mech:OnDissolveStart( state)
	--self:EnableMechFunctionality( false )
	
	EntityService:RemovePropsInEntityBounds( self.entity )
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.5, false )

	state:SetDurationLimit( 0.5 )
end

function mech:OnDissolveEnd()
	QueueEvent( "LuaGlobalEvent", event_sink, "InitialSpawnEnded", {} )
	self:EnableMechFunctionality( true )
end

function mech:OnAnimationMarkerReached(evt)
	if ( evt:GetMarkerName() == "servo" ) then
		EffectService:AttachEffects( self.entity, "servo" )
	elseif ( evt:GetMarkerName() == "spawned" ) then
		local database = EntityService:GetDatabase( self.entity )
		database:SetInt( "is_spawn", 0 )
		database:SetInt( "initial_spawn", 0 )
		self.fsm:ChangeState("shockwave")
	elseif ( evt:GetMarkerName() == "landed" ) then
		local effect = EntityService:SpawnEntity( "effects/mech/jump_portal_shockwave", self.entity, EntityService:GetTeam(self.entity) )
        EntityService:PropagateEntityOwner( effect, self.entity )
	end
end

function mech:OnDamageEvent( evt )
	LampService:ReportMechDamage()
end

function mech:OnReactivateMechRequest( evt )
	if self.mech_reactivator_flow_field == INVALID_ID then
		return
	end 

	local state_name = self.fsm:GetCurrentState()
	if state_name ~= "deactivate" then
		return
	end

	self.reactivator_id = PlayerService:GetPlayerForEntity(evt:GetOwner())

	local state = self.fsm:GetState(state_name)
	state:Exit()

	local camera_entity = CameraService:GetPlayerCamera(self.player_id)
	CameraService:SetFollowTarget( camera_entity, self.entity )

	EntityService:SpawnAndAttachEntity("items/special/multiplayer_revive_boost", evt:GetOwner() )
	EntityService:SpawnAndAttachEntity("items/special/multiplayer_revive_boost", self.entity )

	self.reactivationActive = false
end

local g_deactivate_mech_components = {
	"HealthComponent",
	"TypeComponent",
	"MechComponent",
	"HealthLinkComponent",
}

function mech:OnInteractWithEntity( event )
	if event:GetEvent() == "InteractWithEntityStarted" then
		self.reactivationActive = true
		EffectService:AttachEffects( self.entity, "reviving")
	end
	if event:GetEvent() == "InteractWithEntityEnded" then
		if self.reactivationActive == true then
			self.reactivationActive = false
			EffectService:DestroyEffectsByGroup( self.entity, "reviving" )
			self:CleanupReactivationSkulls()
			self:InitReactivationSkulls()
		end
	end
end

function mech:GetDeathSkullCooldown()
	local difficulty = DifficultyService:GetDifficulty()
    local difficultyHelper = reflection_helper( difficulty )
	return difficultyHelper.death_skull_cooldown
end

function mech:GetDeathSkullAdditionalTime()
	local difficulty = DifficultyService:GetDifficulty()
    local difficultyHelper = reflection_helper( difficulty )
	return difficultyHelper.death_skull_penalty_time
end

function mech:GetDeathSkullMaxCount()
	local difficulty = DifficultyService:GetDifficulty()
    local difficultyHelper = reflection_helper( difficulty )
	return difficultyHelper.death_skull_max_count
end

function mech:GetDeathSkullCount()
	local playerEntity = PlayerService:GetGlobalPlayerEntity( self.player_id )
 	local playerGameStateComponent = EntityService:GetComponent( playerEntity, "PlayerGameStateComponent" )
	if playerGameStateComponent == nil then
		return 0
	end
	
	local helper = reflection_helper( playerGameStateComponent ) 
    local container = rawget( helper.mech_skull_cooldowns, "__ptr" );
	local count = container:GetItemCount()
	return count
end

function mech:TakeAwayResources( deathSkullCount )
	local difficulty = DifficultyService:GetDifficulty()
	local difficultyHelper = reflection_helper( difficulty )
	local scale = ( 1.0 - ( difficultyHelper.death_skull_resource_decrease_percent / 100.0 ) * deathSkullCount )
	scale = Clamp( scale, 0.0, 1.0 )
	local player_team = PlayerService:GetPlayerTeam( self.player_id )
	--PlayerService:ScaleTeamGlobalResources( player_team, scale )
	local beforeCarbonium = PlayerService:GetResourceAmount( self.player_id, "carbonium" )
	local beforeSteel = PlayerService:GetResourceAmount( self.player_id, "steel" )
	PlayerService:ScaleTeamBasicResources( player_team, scale )
	local afterCarbonium = PlayerService:GetResourceAmount( self.player_id, "carbonium" )
	local afterSteel = PlayerService:GetResourceAmount( self.player_id, "steel" )
	local diffCarbonium = afterCarbonium - beforeCarbonium
	local diffSteel = afterSteel - beforeSteel
	QueueEvent("DroppedResourceEvent", self.entity, "carbonium", diffCarbonium )
	QueueEvent("DroppedResourceEvent", self.entity, "steel", diffSteel )
end

function mech:AddDeathSkull( penalty )
	local playerEntity = PlayerService:GetGlobalPlayerEntity( self.player_id )
 	local playerGameStateComponent = EntityService:GetComponent( playerEntity, "PlayerGameStateComponent" )
	if playerGameStateComponent then
		self:CleanupReactivationSkulls()
		local deathSkullCount = self:GetDeathSkullCount()
		if penalty == true and deathSkullCount > 0 then 
			self:TakeAwayResources( deathSkullCount )
	 	end

	 	local deathSkullMaxCount = self:GetDeathSkullMaxCount()
	 	if deathSkullCount < deathSkullMaxCount or deathSkullMaxCount == 0 then

			local helper = reflection_helper( playerGameStateComponent ) 
		    local container = rawget(helper.mech_skull_cooldowns, "__ptr");
			local item = container:CreateItem()
			item:SetValue( tostring(1.0) )
		end
	end
end

function mech:InitReactivationSkulls()
	local playerEntity = PlayerService:GetGlobalPlayerEntity( self.player_id )
 	local playerGameStateComponent = EntityService:GetComponent( playerEntity, "PlayerGameStateComponent" )
 	if playerGameStateComponent then
		local helper = reflection_helper( playerGameStateComponent ) 
		local container = rawget(helper.mech_skull_reactivations, "__ptr");
		local count = self:GetDeathSkullCount()
		for i = 1, count, 1 do
			local item = container:CreateItem()
			item:SetValue( tostring(1.0) )
		end
	end
end

function mech:CleanupReactivationSkulls()
	local playerEntity = PlayerService:GetGlobalPlayerEntity( self.player_id )
 	local playerGameStateComponent = EntityService:GetComponent( playerEntity, "PlayerGameStateComponent" )
 	if playerGameStateComponent then
		local helper = reflection_helper( playerGameStateComponent ) 
		local container = rawget(helper.mech_skull_reactivations, "__ptr");
		local count = self:GetDeathSkullCount()
		for i = count, 0, -1 do
			container:EraseItem( i )
		end
	end
end

function mech:UpdateDeathSkull( dt )
	local playerEntity = PlayerService:GetGlobalPlayerEntity( self.player_id )
 	local playerGameStateComponent = EntityService:GetComponent( playerEntity, "PlayerGameStateComponent" )
 	if playerGameStateComponent then
		local helper = reflection_helper( playerGameStateComponent ) 
		local database = EntityService:GetDatabase( self.entity )
		local is_deactivated = database:GetIntOrDefault( "is_deactivated", 0 )
		if is_deactivated == 0 then
	        local container = rawget(helper.mech_skull_cooldowns, "__ptr");
		    local count = container:GetItemCount()
			if count > 0 then
				local item = container:GetItem( 0 )
				local maxCooldown = self:GetDeathSkullCooldown()
				local cooldown = ( ( tonumber( item:GetValue() ) * maxCooldown ) - dt ) / maxCooldown
				item:SetValue( tostring( cooldown ) )
				if tonumber( item:GetValue() ) <= 0 then
					container:EraseItem( 0 )
				end
			end
		else
	        local container = rawget(helper.mech_skull_reactivations, "__ptr");
		    local count = container:GetItemCount()
			if self.reactivationActive == true and count > 0 then
				local item = container:GetItem( 0 )
				local maxCooldown = self:GetDeathSkullAdditionalTime()
				local cooldown = ( ( tonumber( item:GetValue() ) * maxCooldown ) - dt ) / maxCooldown
				item:SetValue( tostring( cooldown ) )
				if tonumber( item:GetValue() ) <= 0 then
					container:EraseItem( 0 )
				end
			end
		end
	end
end 

function mech:GetAdditionalReactivationTime()
	return self:GetDeathSkullCount() * self:GetDeathSkullAdditionalTime()
end 

function mech:OnUpdateExecute( state, dt )
	self:UpdateDeathSkull( dt )
end

function mech:OnDeactivateEnter(state)
	self.death_duration = GetLogicTime() + self.data:GetFloatOrDefault( "death_explosion_timer", 10 )

	local database = EntityService:GetDatabase( self.entity )
	database:SetInt( "is_deactivated", 1 )
	database:SetFloat( "death_timer", self.death_duration )

	local childreen = EntityService:GetChildren(self.entity, true)
	for ent in Iter(childreen ) do
		if (EntityService:GetComponent( ent, "SkillLinkUnitComponent") ~= nil ) then
			EntityService:RemoveEntity( ent )
		end
	end

	local mechComponent = EntityService:GetComponent( self.entity, "MechComponent")
	if ( mechComponent ~= nil ) then
		local helper = reflection_helper( mechComponent )
		if helper.time_warp_ent.id ~= INVALID_ID then
			EntityService:RemoveEntity( helper.time_warp_ent.id )
			helper.time_warp_ent.id = INVALID_ID
		end
	end

	self:DisableTimeStateMachine()

	EffectService:AttachEffects( self.entity, "deactivated")
	EntityService:RequestDestroyPattern( self.entity, "deactivated", false )

	for component_name in Iter(g_deactivate_mech_components) do
		EntityService:DisableComponent( self.entity, component_name )
	end

	EntityService:DisableCollisions( self.entity )

	self.mech_reactivator = EntityService:SpawnAndAttachEntity( "player/player_reactivator", self.entity, "att_omni_light" )
	self:RegisterHandler( self.mech_reactivator, "InteractWithEntityRequest", "OnReactivateMechRequest")
	self:RegisterHandler( self.mech_reactivator, "LuaGlobalEvent", "OnInteractWithEntity")
	
	local mech_reactivator_database = EntityService:GetDatabase( self.mech_reactivator )
	mech_reactivator_database:SetFloat("harvest_duration", 0.033 + self:GetAdditionalReactivationTime() )
	self:InitReactivationSkulls()

	self.mech_reactivator_flow_field = EntityService:SpawnEntity( "player/player_reactivator_flow_field", self.mech_reactivator, "" )
	self.mech_reactivator_player_blocker = EntityService:SpawnEntity( "player/player_reactivator_player_blocker", self.mech_reactivator, "" )

	self.special_item = ItemService:GetEquippedItem( self.entity, "SPECIAL")
	if self.special_item ~= INVALID_ID then
		QueueEvent("UnequipItemRequest", self.entity, self.special_item, "SPECIAL")
	end

	QueueEvent("PlayerDownEvent", event_sink, self.player_id, self.killer_id or INVALID_ID )

	EntityService:SetMaterial( self.entity, "highlight/resistance_blue_skinned", "deactivated" )
	EntityService:SetMaterial( self.entity, "highlight/alarm_red_skinned", "alarm" )

	self.reactivationHighlightTimer = 0.0
end

function mech:DestroyMech()
	if self.destroyed then
		return
	end

	self.destroyed = true

	if self.data:GetIntOrDefault("disable_drop", 0) == 0 then
		DestroyPlayerItems(self.entity, self.player_id)
		DropPlayerItems(self.entity, self.player_id)
	end

	if self.mech_reactivator_flow_field ~= nil and self.mech_reactivator_flow_field ~= INVALID_ID then
		EntityService:RemoveEntity( self.mech_reactivator_flow_field )
		self.mech_reactivator_flow_field = INVALID_ID
	end

	if self.mech_reactivator_player_blocker ~= nil and self.mech_reactivator_player_blocker ~= INVALID_ID then
		EntityService:RemoveEntity( self.mech_reactivator_player_blocker )
		self.mech_reactivator_player_blocker = INVALID_ID
	end

	self:AddDeathSkull( true )

	EffectService:DestroyEffectsByGroup( self.entity, "reviving" )

	QueueEvent( "PlayerPawnDestroyedEvent", self.entity, self.player_id )
	QueueEvent( "PlayerDiedEvent", self.entity, self.player_id, self.killer_id or INVALID_ID, self.killer_damage or "physical" )
end

function mech:OnDeactivateExecute(state, dt)
	local database = EntityService:GetDatabase( self.entity )
	local has_other_players_alive = HasOtherAlivePlayersInTeam( self.player_id )
	local spawn_point_destroyed = PlayerService:GetPlayerSpawnPoint( self.player_id ) == INVALID_ID
	local interact_active = PlayerService:IsActionActive( self.entity, "interact") and not spawn_point_destroyed

	if spawn_point_destroyed then 
		if not has_other_players_alive then
			self:DestroyMech()
			return
		end
		self.death_duration = self.death_duration + dt
		database:SetFloat( "death_timer", 0.0 )
	elseif interact_active then
		self.death_duration = self.death_duration - dt * ( 5.0 ) -- revive countdown speedup 'parameter' 
		database:SetFloat( "death_timer", self.death_duration )
	else 
		database:SetFloat( "death_timer", self.death_duration )
	end

	local death_duration_limit = database:GetFloatOrDefault("death_explosion_timer", 10);
	local death_duration_left = self.death_duration - GetLogicTime();
	local death_progress = Clamp( death_duration_left / death_duration_limit, 0.0, 1.0 );

	if self.mech_reactivator ~= INVALID_ID and EntityService:IsAlive( self.mech_reactivator ) then
		local progress = ( 1.0 - death_progress ) * ( 1.0 - death_progress )
		EntityService:SetGraphicsUniform( self.entity, "cProgress", math.floor( 4 * progress )  )
		progress =  math.floor( 16 * progress ) 
		local latency = Lerp( 0.6, 0.15, progress / 16 )
		local reactivatorDatabase = EntityService:GetOrCreateDatabase( self.mech_reactivator )
		reactivatorDatabase:SetFloat( "latency", latency );

		self.reactivationHighlightTimer = self.reactivationHighlightTimer - ( dt * ( 1.0 / latency ) )
		if self.reactivationHighlightTimer <= 0 or interact_active then
			QueueEvent("HudDamageHighlightRequest", self.entity )
			self.reactivationHighlightTimer = 1.0
		end

	 	self.predicate = self.predicate or { signature="WreckTeamComponent"}
		local wrecks = FindService:FindEntitiesByPredicateInRadius( self.mech_reactivator, 6, self.predicate )
		for i = 1, #wrecks do	
			local dissolveTime = RandFloat( 0.5, 1.0 )
			EntityService:DissolveEntity( wrecks[i], dissolveTime );
		end
	end

	if self.death_duration > GetLogicTime() then
		return
	end

	if MissionService:IsPlayerRespawnBlocked() then
		return
	end

	self:DestroyMech()
end

function mech:OnDeactivateExit(state)
	local database = EntityService:GetDatabase( self.entity )
	database:SetInt( "is_deactivated", 0 )

	self:EnableTimeStateMachine()

	EntityService:RemoveMaterial(self.entity, "deactivated")
	EntityService:RemoveMaterial(self.entity, "alarm")
	EntityService:RemoveGraphicsUniform( self.entity, "cProgress" )
	EffectService:DestroyEffectsByGroup( self.entity, "deactivated" )

	for component_name in Iter(g_deactivate_mech_components) do
		EntityService:EnableComponent( self.entity, component_name )
	end

	EntityService:EnableCollisions( self.entity )

	if self.special_item ~= INVALID_ID then
		QueueEvent("EquipItemRequest", self.entity, self.special_item, "SPECIAL")
	end

	local restore_health_pct = self.data:GetFloatOrDefault("reactivate_health_pct", 0.5) * 100
	EntityService:RemoveComponent( self.entity, "DeadStateComponent" )
	HealthService:SetHealthInPercentage( self.entity, restore_health_pct )
	HealthService:ActivateDestructionLevelComponent( self.entity )
	EffectService:SpawnEffects( self.entity, "reactivated")

	self:UnregisterHandler( self.mech_reactivator, "InteractWithEntityRequest", "OnReactivateMechRequest")
	self:UnregisterHandler( self.mech_reactivator, "LuaGlobalEvent", "OnInteractWithEntity")

	EntityService:RemoveEntity( self.mech_reactivator )
	EntityService:RemoveEntity( self.mech_reactivator_flow_field )
	EntityService:RemoveEntity( self.mech_reactivator_player_blocker )

	QueueEvent( "PlayerReactivatedEvent", event_sink, self.player_id, self.reactivator_id or self.player_id )

	self:AddDeathSkull( false )

	EffectService:DestroyEffectsByGroup( self.entity, "reviving" )

	self.mech_reactivator = INVALID_ID
	self.mech_reactivator_flow_field = INVALID_ID
	self.mech_reactivator_player_blocker = INVALID_ID
	self.killer_id = INVALID_ID
	self.killer_damage = nil
end

function mech:OnEntityKilledEvent( evt )
	self.killer_id = evt:GetKillerPlayer()
	self.killer_damage = evt:GetDamageType()
end

function mech:OnDestroyRequest( evt )
	LampService:ReportMechDestroy()

	if self._OnDestroyRequest then
		self:_OnDestroyRequest( evt )
	end
	local player_team = PlayerService:GetPlayerTeam( self.player_id )
	local has_other_players = #PlayerService:GetConnectedPlayersFromTeam( player_team ) > 1
	if ( has_other_players ) then
		local spawn_point_destroyed = PlayerService:GetPlayerSpawnPoint( self.player_id ) == INVALID_ID or MissionService:IsPlayerRespawnBlocked()
		local has_other_players_alive = HasOtherAlivePlayersInTeam( self.player_id )
		if spawn_point_destroyed and not has_other_players_alive then
			self:DestroyMech()
		else
			self.fsm:ChangeState("deactivate")
		end
	else
		self:DestroyMech()
	end
end

function mech:OnRevealHiddenEntityEvent( evt )
	local dialogs = 
	{
	 	{"gui/hud/dialogs/ashley","DIALOG/generic/ashley_treasure_found_01", "voice_over/generic/ashley_treasure_found_01"},
	 	{"gui/hud/dialogs/ashley","DIALOG/generic/ashley_treasure_found_02", "voice_over/generic/ashley_treasure_found_02"},
	 	{"gui/hud/dialogs/ashley","DIALOG/generic/ashley_treasure_found_03", "voice_over/generic/ashley_treasure_found_03"},
	 	{"gui/hud/dialogs/mech","DIALOG/generic/mech_treasure_found_01", "voice_over/generic/mech_treasure_found_01"},
	 	{"gui/hud/dialogs/mech","DIALOG/generic/mech_treasure_found_02", "voice_over/generic/mech_treasure_found_02"},
	 	{"gui/hud/dialogs/mech","DIALOG/generic/mech_treasure_found_03", "voice_over/generic/mech_treasure_found_03"},
	}
	local idx = RandInt(1, #dialogs)
	
	local currentDialog = dialogs[idx]
	
	self.soundDuration = SoundService:GetSoundDuration( currentDialog[3] )
	GuiService:ShowDialog( currentDialog[1],currentDialog[2],currentDialog[3], 0, self.soundDuration, false, true, false, 0, false )

end

function mech:RecreateComponentsAfterLoad()
	--ShadowCheckerComponent
	self:OnLeaveShadowEvent()

	QueueEvent("RecreateComponentFromBlueprintRequest", self.entity, "ShadowCheckerComponent" )
	self.player_id = PlayerService:GetPlayerForEntity( self.entity )
end

function mech:OnLoad()
	day_cycle_machine.OnLoad( self )

	if self._dayCycleFSM then
		self:_ChangeDayState( "" )
		local timeOfDay = EnvironmentService:GetTimeOfDay()
		self:_ChangeDayState( timeOfDay )
	end

	if ( self.version == nil or self.version < 1 ) then
		EntityService:RemoveGraphicsUniform( self.entity, 0,  "cDissolveAmount")

		if self.mfsm == nil then 
			self.mfsm = self:CreateStateMachine()
			self.mfsm:AddState( "update", {execute="OnUpdateExecute"} )
			self.mfsm:ChangeState( "update" )
		end

		self.version = 1
	end

	if not self:HasEventHandler( self.entity, "EnterShadowEvent") then
		self:RegisterHandler( self.entity, "EnterShadowEvent",  "OnEnterShadowEvent" )
		self:RegisterHandler( self.entity, "LeaveShadowEvent",  "OnLeaveShadowEvent" )
	end

	self:RecreateComponentsAfterLoad()
end

-- deprecated
function mech:OnInvisibilityEnter( state )
end
function mech:OnInvisibilityExit( state )
end
function mech:OnItemEquippedEvent( evt )
end
function mech:OnEnterInvisiblityEvent( evt )
end
function mech:OnExitInvisiblityEvent( evt )
end
--- 

function mech:OnPortalOpenEnter( state )
	local has_players_nearby = teleport_machine.TeleportEntity(self, self.entity, EntityService:GetPosition( self.entity))

	EntityService:SetVisible( self.entity, false )
	EntityService:FadeEntity( self.entity, DD_FADE_OUT, 0.0, false )
	self:UpdateChildrenDissolveAmount( self.entity, DD_FADE_OUT, 0, true )

	local type = EntityService:GetType(self.entity)
	EntityService:ChangeType( self.entity, type .. "|invisible" )

	EffectService:SpawnEffects( self.entity, "jump_portal" )
		
	if has_players_nearby then
		state:SetDurationLimit( RandFloat( 1.5, 3.5 ) )
	else
		state:SetDurationLimit( 2.0 )
	end
end

function mech:OnPortalOpenExecute( state, dt )
end

function mech:OnPortalOpenExit( state )
	local type = EntityService:GetType(self.entity)
	type = string.gsub(type, "|invisible", "", 1 )

	EntityService:ChangeType( self.entity, type )

	EntityService:SetVisible( self.entity, true )
	EffectService:SpawnEffect( self.entity, "effects/mech/jump_portal_exit", "att_jump" )

	EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.5, false )
	self:UpdateChildrenDissolveAmount( self.entity, DD_FADE_IN, 0.5, true )
	self.fsm:ChangeState("initial_spawn")
end

function mech:OnInitialSpawnEnter( state )
	local database = EntityService:GetDatabase( self.entity )
	database:SetInt( "is_spawn", 1 )
	state:SetDurationLimit( 0.5 )
end

function mech:OnInitialSpawnExecute( state, dt )	
end

function mech:OnInitialSpawnExit( state )
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.0, false )
end

function mech:OnShockwaveEnter( state )
	state:SetDurationLimit( 1 )
end

function mech:EnableMechFunctionality( enable )
	if enable then
		QueueEvent( "RecreateComponentFromBlueprintRequest", self.entity, "MechComponent")

		if not self.is_bot then
			QueueEvent( "CreateActionMapperRequest", self.entity, "MechActionMapper", MECH_ACTION_MAPPER_NAME, 0 )
		end
	else
		if not self.is_bot then
			QueueEvent( "RemoveActionMapperRequest", self.entity, MECH_ACTION_MAPPER_NAME )
		end
		EntityService:RemoveComponent( self.entity, "MechComponent" )
	end
end

function mech:OnShockwaveExit( state )
	HealthService:SetImmortality( self.entity, false  )

	QueueEvent( "LuaGlobalEvent", event_sink, "InitialSpawnEnded", {} )

	self:EnableMechFunctionality( true )
end

return mech
