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

	self.lastItemType = ""
	self.lastItemEnt = nil

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "start", { from="*", enter="OnDrillStartEnter", execute="OnDrillStartExecute",  exit="OnDrillStartExit" } )
	self.sm:AddState( "stop", { from="*", enter="OnDrillStopEnter", execute="OnDrillStopExecute",  exit="OnDrillStopExit" } )
end

function drill:OnDrillStartEnter( state )
	state:SetDurationLimit( 0.75 )
	
	EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75)
	EntityService:FadeEntity( self.lastItemEnt, DD_FADE_OUT, 0.75)
end

function drill:OnDrillStartExecute( state )
end

function drill:OnDrillStartExit( state )
end

function drill:OnDrillStopEnter( state )
	state:SetDurationLimit( 0.75 )
	
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.75)
	EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.75)
end

function drill:OnDrillStopExecute( state )
end

function drill:OnDrillStopExit( state )
end

function drill:OnEquipped()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
	self.duration = 0.0
end

function drill:OnActivate()
	if ( self.drilling == true ) then
		self:OnExecuteDrilling()
	end
	
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated()  ) then
		self:RegisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
		self.lastItemType = ownerData:GetStringOrDefault( "RIGHT_HAND_item_type", "" )
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		self.sm:ChangeState("start")
	end

	ownerData:SetString( "RIGHT_HAND_item_type", "drill" )
	ownerData:SetFloat( "RIGHT_HAND_use_speed", 1 )

	PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_drill.wav", true, 5 )
end

function drill:OnDeactivate()
	PlayerService:StopPadHapticFeedback( 0 )

	local ownerData = EntityService:GetDatabase( self.owner );
	if ownerData ~= nil then
		ownerData:SetString( "RIGHT_HAND_item_type", self.lastItemType )
		ownerData:SetFloat( "RIGHT_HAND_use_speed", 0 );
	end

	EffectService:DestroyEffectsByGroup(self.item, "dig")
	self:UnregisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
	self.drilling = false;
	self.sm:ChangeState("stop")
	self.duration = 0.0
	return true
end

local function GetInteractiveEntity( owner )
	local component = reflection_helper( EntityService:GetComponent(owner, "MechComponent") )
	return component.interactive_ent.id;
end

function drill:OnExecuteDrilling()
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
