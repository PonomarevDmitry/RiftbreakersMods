require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")

class 'drill' ( item )

function drill:__init()
	item.__init(self)
end

function drill:OnInit()
	self.radius   = self.data:GetFloat( "radius" )
	self.amount   = self.data:GetFloat( "amount" )
	self.resource = self.data:GetString( "resource" )

	self.lastItemEnt = nil

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "start", { from="*", enter="OnDrillStartEnter", execute="OnDrillStartExecute",  exit="OnDrillStartExit" } )
	self.sm:AddState( "stop", { from="*", enter="OnDrillStopEnter", execute="OnDrillStopExecute",  exit="OnDrillStopExit" } )
end

function drill:OnDrillStartEnter( state )
	state:SetDurationLimit( 0.75 )
	if not is_server then
		return
	end

	EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75)

	if self.lastItemEnt ~= nil then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_OUT, 0.75)
	end
end

function drill:OnDrillStartExecute( state )
end

function drill:OnDrillStartExit( state )
end

function drill:OnDrillStopEnter( state )
	state:SetDurationLimit( 0.75 )
	if not is_server then
		return
	end
	
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.75)
	
	if self.lastItemEnt ~= nil then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.75)
	end
end

function drill:OnDrillStopExecute( state )
end

function drill:OnDrillStopExit( state )
end

function drill:OnEquipped()
	self.duration = 0.0
	if not is_server then
		return
	end
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

function drill:OnActivate()
	if not is_server then
		return
	end
	if ( self.drilling == true ) then
		self:OnExecuteDrilling()
	end
	
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated()  ) then
		self:RegisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		self.sm:ChangeState("start")
	end

	ownerData:SetString( "RIGHT_HAND_item_type", "drill" )
	ownerData:SetFloat( "RIGHT_HAND_use_speed", 1 )
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
	PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_drill.wav", true, 5 )
end

function drill:OnDeactivate()
	if not is_server then
		return true
	end
    local playerId = PlayerService:GetPlayerForEntity(self.owner )
	PlayerService:StopPadHapticFeedback( playerId )

	self:RestoreSlotTypeAndPose("RIGHT_HAND", 0.0)

	EffectService:DestroyEffectsByGroup(self.item, "dig")
	self:UnregisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
	self.drilling = false;
	self.sm:ChangeState("stop")
	self.duration = 0.0
	return true
end

local function GetInteractiveEntity( owner )
	local component = EntityService:GetComponent(owner, "MechComponent")
	if component == nil then
		return INVALID_ID
	end

	return reflection_helper( component ).interactive_ent.id;
end

function drill:OnExecuteDrilling()
	if not is_server then
		return
	end

	local interactive = GetInteractiveEntity( self.owner )
	local database = EntityService:GetDatabase( interactive )
	local cooldown =  ItemService:GetCooldown( self.entity)
	self.duration = self.duration +  (1.0 / 30.0)
	
	if ( self.duration < cooldown ) then
		return
	end

	self.duration = 0.0

	if (PlayerService:HarvestResource( interactive, self.item ) == false ) then
		ItemService:InteractWithEntity( interactive, self.owner )
	
		EffectService:AttachEffects( interactive, "treasure" )
	end
end

function drill:OnAnimationStateChangedEvent( evt )
	local newStateName = evt:GetNewStateName()
	if ( newStateName == "middle_drill" ) then
		EffectService:AttachEffects(self.item, "dig")
		self.drilling = true;
	end
end  

function drill:DissolveShow()
	-- must be empty!
end


return drill
