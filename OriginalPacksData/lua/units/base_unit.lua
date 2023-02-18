require("lua/units/units_utils.lua")

class 'base_unit' ( LuaEntityObject )

function base_unit:__init()
	LuaEntityObject.__init(self, self)
end

local CURRENT_BASE_UNIT_VERSION = 1

function base_unit:init()
	SetupUnitScale( self.entity, self.data )

	self.lastDamageGenericTime = 0

	self:CreateSoundStateMachine()

	self:RegisterHandler( self.entity, "RunningStateChangeEvent", "_OnRunningStateChange" )
	self:RegisterHandler( self.entity, "DestroyRequest",  "_OnDestroyRequest" )
    self:RegisterHandler( self.entity, "DamageEvent",  "_OnDamageEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "_OnAnimationMarkerReached" )
	self:RegisterHandler( self.entity, "AnimationStateChangedEvent", "_OnAnimationStateChanged" )

	self:OnInit()

	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION

	Assert( self.wreck_type ~= nil, "ERROR: self.wreck_type is required to be set in unit:OnInit!");
	Assert( self.wreckMinSpeed ~= nil, "ERROR: self.wreckMinSpeed is required to be set in unit:OnInit!");
end

function base_unit:OnInit()
end

function base_unit:CreateSoundStateMachine( )
	self.soundFSM = self:CreateStateMachine()
	self.soundFSM:AddState( "idle", {interval=10.0} )
	self.soundFSM:AddState( "move", {enter="_OnSoundMoveEnter", exit="_OnSoundMoveExit", interval=0.5} )
	self.soundFSM:AddState( "run", {enter="_OnSoundRunEnter", exit="_OnSoundRunExit", interval=0.5} )
	self.soundFSM:ChangeState("idle")
end

function base_unit:_OnDamageEvent( evt )
	if not evt:GetDamageOverTime() then 
		local currentTime = GetLogicTime()
		if self.lastDamageGenericTime + 0.3 < currentTime then
			local isResisted = IsEnumFlagSet( evt:GetEffect(), DAMAGE_EFFECT_RESISTED )
			local isThresholded = IsEnumFlagSet( evt:GetEffect(), DAMAGE_EFFECT_THRESHOLDED )

			if not isResisted and not isThresholded then
				EffectService:AttachEffects( self.entity, "damage_generic" )
				self.lastDamageGenericTime = currentTime
			end
		end
	end

    if self.OnDamageEvent then
        self:OnDamageEvent(evt)
    end
end

function base_unit:_OnDestroyRequest( evt )
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function base_unit:_OnAnimationMarkerReached(evt)
    local markerName = evt:GetMarkerName() 

	local attachEffects = true;
    if self.OnAnimationMarkerReached then
        attachEffects = self:OnAnimationMarkerReached(evt)
    end

	if attachEffects then
		EffectService:AttachEffects( self.entity, markerName  )
	end
end

function base_unit:_OnAnimationStateChanged( evt )
	if self.OnAnimationStateChanged then
        self:OnAnimationStateChanged(evt)
    end
end

function base_unit:ChangeSoundState( name )
	if ( name ~= self.soundFSM:GetCurrentState() ) then
		-- LogService:Log( "ChangeSoundState " .. tostring(self.entity) .. " state: " .. name )	
		self.soundFSM:ChangeState( name )
	end
end

function base_unit:_OnRunningStateChange( evt )
	if evt:GetState() == 1 then
		self:ChangeSoundState("move")
	elseif evt:GetState() == 2 then
		self:ChangeSoundState("run")
	else
		self:ChangeSoundState("idle")
	end
end

function base_unit:_OnSoundMoveEnter( state )
	EffectService:AttachEffects( self.entity, "move_random" )
end
function base_unit:_OnSoundMoveExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "move_random" )
end

function base_unit:_OnSoundRunEnter( state )
	EffectService:AttachEffects( self.entity, "run" )
end
function base_unit:_OnSoundRunExit( state )
	EffectService:DestroyEffectsByGroup( self.entity, "run" )
end

function  base_unit:OnLoad()
	if ( self.baseUnitVersion == nil or self.baseUnitVersion < 1 ) then
		self:UnregisterHandler( self.entity, "IdleStateChangedEvent", "_OnIdleStateChanged" )
		self:DestroyStateMachine(self.soundFSM)
		self:CreateSoundStateMachine()
		self.baseUnitVersion = 1
	end
	
	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION
end
	
return base_unit
