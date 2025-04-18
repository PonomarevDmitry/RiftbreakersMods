require("lua/units/units_utils.lua")

class 'base_unit' ( LuaEntityObject )

function base_unit:__init()
	LuaEntityObject.__init(self, self)
end

local FXSYSTEM_HANDLES_SOUND 	= 2
local CURRENT_BASE_UNIT_VERSION = FXSYSTEM_HANDLES_SOUND

function base_unit:init()
	SetupUnitScale( self.entity, self.data )

	self.lastDamageGenericTime = 0

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

function base_unit:_OnDamageEvent( evt )
	-- `damage_generic` spawning moved to FxSystem so it is done only on client side!

    if self.OnDamageEvent then
        self:OnDamageEvent(evt)
    end
end

function base_unit:_OnDestroyRequest( evt )
	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )

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

function base_unit:OnLoad()
	if ( self.baseUnitVersion == nil or self.baseUnitVersion < 1 ) then
		self:UnregisterHandler( self.entity, "IdleStateChangedEvent", "_OnIdleStateChanged" )

		if self.soundFSM then
			self:DestroyStateMachine(self.soundFSM)
		end
		
		self.soundFSM = nil
	elseif self.baseUnitVersion < FXSYSTEM_HANDLES_SOUND then
		self:UnregisterHandler( self.entity, "RunningStateChangeEvent", "_OnRunningStateChange" )

		if self.soundFSM then
			self:DestroyStateMachine(self.soundFSM)
		end

		self.soundFSM = nil
	end
	
	self.baseUnitVersion = CURRENT_BASE_UNIT_VERSION
end
	
-- LEGACY
function base_unit:_OnRunningStateChange( evt )
end

function base_unit:_OnSoundMoveEnter( state )
end
function base_unit:_OnSoundMoveExit( state )
end

function base_unit:_OnSoundRunEnter( state )
end

function base_unit:_OnSoundRunExit( state )
end

return base_unit
