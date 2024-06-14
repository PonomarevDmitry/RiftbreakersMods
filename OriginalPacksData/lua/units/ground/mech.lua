local day_cycle_machine = require("lua/utils/day_cycle_machine.lua")
require("lua/utils/table_utils.lua")

class 'mech' ( day_cycle_machine )

function mech:UpdateChildrenDissolveAmount( entity, type, time )
	local children =  EntityService:GetChildren( entity, false )
	for child in Iter(children) do
		local itemType = ItemService:GetItemType(child);
		if ( itemType ~= "interactive" and itemType ~= "equipment" and itemType ~= "" and itemType ~= "lift" ) then			
			EntityService:FadeEntity( child, type, time)
			self:UpdateChildrenDissolveAmount( child, type, time )
		end
	end
end

function mech:__init()
	day_cycle_machine.__init(self,self)
end

function mech:init()
	self:EnableTimeStateMachine()
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
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

	self.version = 1

	if self._OnInit then
		self:_OnInit()
	end
end

function mech:OnRiftTeleportStartEvent()
	PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_teleport.wav", false, 5 )
end

function mech:OnEnterShadowEvent()
	EnvironmentService:SetResistance( self.entity, "sunburn", 0.0, "shadow")
end

function mech:OnLeaveShadowEvent()
	EnvironmentService:RemoveResistance( self.entity, "sunburn", "shadow")
end

function mech:OnDissolveStart( state)
	self:EnableMechFunctionality( false )
	
	EntityService:RemovePropsInEntityBounds( self.entity )
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 1.0 )

	state:SetDurationLimit( 1.0 )
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
		EffectService:SpawnEffect( self.entity, "effects/mech/jump_portal_shockwave" )
	end
end

function mech:OnDamageEvent( evt )
	LampService:ReportMechDamage()
end

function mech:OnDestroyRequest( evt )
	LampService:ReportMechDestroy()

	if self._OnDestroyRequest then
		self:_OnDestroyRequest( evt )
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

function mech:OnLoad()
	day_cycle_machine.OnLoad( self )

	self:_ChangeDayState( "" )
	local timeOfDay = EnvironmentService:GetTimeOfDay()
	self:_ChangeDayState( timeOfDay )

	if ( self.version == nil or self.version < 1 ) then
		EntityService:RemoveGraphicsUniform( self.entity, 0,  "cDissolveAmount")
		self.version = 1
	end
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
	EntityService:SetVisible( self.entity, false )
	EntityService:FadeEntity( self.entity, DD_FADE_OUT, 0.0)
	self:UpdateChildrenDissolveAmount( self.entity,DD_FADE_OUT, 0 )

	EffectService:SpawnEffects( self.entity, "jump_portal" )
	state:SetDurationLimit( 2 )
end

function mech:OnPortalOpenExecute( state, dt )
end

function mech:OnPortalOpenExit( state )
	EntityService:SetVisible( self.entity, true )
	EffectService:SpawnEffect( self.entity, "effects/mech/jump_portal_exit", "att_jump" )
	self:UpdateChildrenDissolveAmount( self.entity, DD_FADE_IN, 0.5 )
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.5)
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
	EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.0)
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