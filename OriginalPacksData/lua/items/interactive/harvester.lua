require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")

class 'harvester' ( item )

function harvester:__init()
	item.__init(self)
end

function harvester:OnInit()
	self.lastItemEnt = nil

	self.version = 1
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "start", { from="*", enter="OnHarvestStartEnter", execute="OnHarvestStartExecute",  exit="OnHarvestStartExit" } )
	self.sm:AddState( "stop", { from="*", enter="OnHarvestStopEnter", execute="OnHarvestStopExecute",  exit="OnHarvestStopExit" } )
end

local function GetInteractiveEntity( owner )
	local component = EntityService:GetComponent(owner, "MechComponent")
	if component == nil then
		return INVALID_ID
	end

	return reflection_helper( component ).interactive_ent.id;
end

function harvester:OnHarvestStartEnter( state )
	state:SetDurationLimit( 0.75 )
	if not is_server then
		return
	end
	EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75)

	if self.lastItemEnt ~= nil then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_OUT, 0.75)
	end

	QueueEvent( "HarvestStartEvent", GetInteractiveEntity( self.owner ) )
end

function harvester:OnHarvestStartExecute( state )
end

function harvester:OnHarvestStartExit( state )
end

function harvester:OnHarvestStopEnter( state )
	state:SetDurationLimit( 0.75 )
	if not is_server then
		return
	end

	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.75)

	if self.lastItemEnt ~= nil then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.75)
	end
end

function harvester:OnHarvestStopExecute( state )
end

function harvester:OnHarvestStopExit( state )
end

function harvester:OnEquipped()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
	self.duration = 0.0
end

function harvester:OnActivate()
	if not is_server then
		return
	end
	if ( self.harvestering == true ) then
		self:OnExecuteHarvesting()
	end
	
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated() ) then
  		self:RegisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		self.sm:ChangeState("start")
	end

	if ItemService:GetItemType( self.entity ) == "equipment" then
		ownerData:SetString( "RIGHT_HAND_item_type", "range_weapon" )
		self.harvestering = true;
	else
		ownerData:SetString( "RIGHT_HAND_item_type", "harvester" )
	end
	ownerData:SetFloat( "RIGHT_HAND_use_speed", 1 )
end

function harvester:OnDeactivate()
	if not is_server then
		return true
	end
	self:RestoreSlotTypeAndPose("RIGHT_HAND", 0.0)

	EffectService:DestroyEffectsByGroup( self.item, "dig" )
	self:UnregisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
	self.harvestering = false;
	self.sm:ChangeState("stop")
	if ( self.timer ~= nil ) then
		EntityService:RemoveEntity( self.timer )
		self.timer = nil
	end
	self.duration = 0.0
	return true
end

function harvester:OnExecuteHarvesting()
	local entity = GetInteractiveEntity( self.owner )

	local database = EntityService:GetDatabase( entity )
	local dur = 2.0
	if ( database ) then
		dur =  database:GetFloatOrDefault("harvest_duration", 2.0 )
	end

	local cooldown = 1.0 / 30.0
	self.duration = self.duration + cooldown

	if ( dur > 2.0 ) then
		if ( self.timer == nil ) then
			local timer  = dur - self.duration;
			self.timer = BuildingService:CreateGuiTimer( entity,  timer )
		else 
			BuildingService:SetGuiTimer( self.timer, self.duration )
		end
	end
	
	if ( self.duration < dur ) then
		return
	end
	
	if (self.timer and EntityService:IsAlive( self.timer )) then
		EntityService:RemoveEntity( self.timer )
	end

	self.timer = nil
	self.duration = 0.0

	ItemService:InteractWithEntity( entity, self.owner )
	EffectService:AttachEffects( entity, "treasure" )
end

function harvester:OnAnimationStateChangedEvent( evt )
	local newStateName = evt:GetNewStateName()
	if ( newStateName == "middle_front_drill" ) then
		EffectService:AttachEffects(self.item, "dig")
		self.harvestering = true;
	end
end  

function harvester:DissolveShow()

end

return harvester
