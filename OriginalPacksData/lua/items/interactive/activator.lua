require("lua/utils/reflection.lua")

local item = require("lua/items/item.lua")

class 'activator' ( item )

function activator:__init()
	item.__init(self)
end

function activator:OnInit()
	self.lastItemType = ""
	self.lastItemEnt = nil
	self.interrupted = false

	self.sm = self:CreateStateMachine()
	self.sm:AddState( "start", { from="*", enter="OnHarvestStartEnter", execute="OnHarvestStartExecute",  exit="OnHarvestStartExit" } )
	self.sm:AddState( "stop", { from="*", enter="OnHarvestStopEnter", execute="OnHarvestStopExecute",  exit="OnHarvestStopExit" } )

	self.harvestStartTime = self.data:GetFloatOrDefault("drill_start_time", 0.66)
end

function activator:OnHarvestStartEnter( state )
	state:SetDurationLimit( self.harvestStartTime )
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( ownerData ~= nil ) then
		ownerData:SetFloat( "RIGHT_HAND_use_speed", 0.75 / self.harvestStartTime )
	end
	
	EntityService:FadeEntity( self.item, DD_FADE_IN, 0.75)
	EntityService:FadeEntity( self.lastItemEnt, DD_FADE_OUT, 0.75)
end

function activator:OnHarvestStartExecute( state )
end

function activator:OnHarvestStartExit( state )
	local ownerData = EntityService:GetDatabase( self.owner );
	if ownerData ~= nil then
		if self.interrupted then 
			ownerData:SetFloat( "RIGHT_HAND_use_speed", 0 )
		else 
			ownerData:SetFloat( "RIGHT_HAND_use_speed", 1 )
		end
	end
end

function activator:OnHarvestStopEnter( state )
	state:SetDurationLimit( 0.75 )
	
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.75)
	EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.75)
end

function activator:OnHarvestStopExecute( state )
end

function activator:OnHarvestStopExit( state )
end

function activator:OnEquipped()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
	self.duration = 0.0
end

function activator:OnActivate()
	if ( self.extractoring == true ) then
		self:OnExecuteHarvesting()
	end
	
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated() ) then
		self:RegisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
		self.lastItemType = ownerData:GetStringOrDefault( "RIGHT_HAND_item_type", "" )
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		self.sm:ChangeState("start")
		self.interrupted = false
	end

	if ( ownerData ~= nil ) then
		if ItemService:GetItemType( self.entity ) == "equipment" then
			ownerData:SetString( "RIGHT_HAND_item_type", "range_weapon" )
			self.extractoring = true;
		else
			ownerData:SetString( "RIGHT_HAND_item_type", "harvester" )
		end
	end
end

function activator:OnDeactivate()
	local ownerData = EntityService:GetDatabase( self.owner );
	if ownerData ~= nil then
		ownerData:SetString( "RIGHT_HAND_item_type", self.lastItemType )
		ownerData:SetFloat( "RIGHT_HAND_use_speed", 0 );
	end

	EffectService:DestroyEffectsByGroup( self.item, "dig" )
	self:UnregisterHandler( self.owner, "AnimationStateChangedEvent", "OnAnimationStateChangedEvent" )
	self.extractoring = false;
	self.sm:ChangeState("stop")
	if ( self.timer ~= nil ) then
		EntityService:RemoveEntity( self.timer )
		self.timer = nil
	end
	self.duration = 0.0
	self.interrupted = true
	return true
end

local function GetInteractiveEntity( owner )
	local component = reflection_helper( EntityService:GetComponent(owner, "MechComponent") )
	return component.interactive_ent.id;
end

function activator:OnExecuteHarvesting()
	local entity = GetInteractiveEntity( self.owner )
	local database = EntityService:GetDatabase( entity )
	local duration = 0.5
	if ( database ~= nil ) then
		duration =  database:GetFloatOrDefault("harvest_duration", 0.5 )
	end
	local cooldown =  ItemService:GetCooldown( self.entity)
	self.duration = self.duration + cooldown

	if ( self.timer == nil and duration > 0.5 ) then
		-- Enable if you need timer on drilling
		--self.timer = BuildingService:AttachGuiTimer( entity, duration - self.duration - cooldown, true )
	end
	
	if ( self.duration < duration ) then
		return
	end

	self.duration = 0.0
	self.timer = nil

	ItemService:InteractWithEntity( entity, self.owner )
	EffectService:AttachEffects( entity, "treasure" )
end

function activator:OnAnimationStateChangedEvent( evt )
	local newStateName = evt:GetNewStateName()
	if ( newStateName == "middle_front_drill" ) then
		EffectService:AttachEffects(self.item, "dig")
		self.extractoring = true;
	end
end  

function activator:DissolveShow()

end

function activator:OnLoad()
	item.OnLoad(self)
	self.harvestStartTime = self.harvestStartTime or self.data:GetFloatOrDefault("drill_start_time", 0.5)
end

return activator
