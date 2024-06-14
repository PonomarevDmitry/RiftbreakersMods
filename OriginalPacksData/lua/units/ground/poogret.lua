require ("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'poogret' ( base_unit )

function poogret:__init()
	base_unit.__init(self, self)
end

function poogret:OnInit()

	self:RegisterHandler( self.entity, "StartLeechEvent",  "OnStartLeechEvent" )
	self:RegisterHandler( self.entity, "FearStartEvent",  "OnFearStartEvent" )
	self:RegisterHandler( self.entity, "FearEndEvent",  "OnFearEndEvent" )

    self.fearFSM = self:CreateStateMachine()
    self.fearFSM:AddState( "fear", { enter="OnEnterFear", execute="OnExecuteFear" } )

	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
	self.currentFood = INVALID_ID
	self.fearTime = self.data:GetFloat( "fear_time" )
	self.fearTimer = self.fearTime

	UnitService:SetStateMachineParam( self.entity, "can_spawn_treasure", 0 )
end

function poogret:OnStartLeechEvent( evt )
	self.food = UnitService:GetCurrentTarget( self.entity, "food" )
	if ( self.food ~= INVALID_ID ) then
		LogService:Log( "self.food ~= INVALID_ID" )
		local interactiveComponent = EntityService:GetComponent( self.food, "InteractiveComponent" )
		if interactiveComponent ~= nil then
			local helper = reflection_helper( interactiveComponent )
			helper.enabled = false
			helper.radius = -1
		end
		HealthService:SetImmortality( self.food, true )
	end
end

function poogret:OnFearStartEvent( evt )
	if ( EffectService:HasEffectByGroup( self.entity, "fear" ) == false ) then
		EffectService:AttachEffects( self.entity, "fear" )
	end	
	
	if ( EffectService:HasEffectByGroup( self.entity, "noticed_food_start" ) == true ) then
		EffectService:DestroyEffectsByGroup( self.entity, "noticed_food_start" )
	end			
end

function poogret:OnFearEndEvent( evt )	
	if ( EffectService:HasEffectByGroup( self.entity, "fear" ) == true ) then
		EffectService:DestroyEffectsByGroup( self.entity, "fear" )
	end	
end

function poogret:OnDamageEvent( evt )
	self.fearFSM:ChangeState( "fear" )
end

function poogret:OnEnterFear( state )
	self.fearTimer = self.fearTime
	UnitService:EmitStateMachineParam( self.entity, "fear_not_ready" )
	UnitService:SetUnitState( self.entity, UNIT_FEAR );
end

function poogret:OnExecuteFear( state, dt )
	self.fearTimer = self.fearTimer - dt

	if ( self.fearTimer <= 0.0 ) then
		UnitService:EmitStateMachineParam( self.entity, "fear_ready" )
		state:Exit();
	end
end

function poogret:OnAnimationMarkerReached( evt )
	local markerName = evt:GetMarkerName() 
	if ( markerName == "eat" ) then
		self.food = UnitService:GetCurrentTarget( self.entity, "food" )

		if ( self.food ~= INVALID_ID ) then
			EntityService:RemoveComponent( self.entity, "TypeComponent" )
			ItemService:InteractWithEntity( self.food, INVALID_ID )
			UnitService:SetStateMachineParam( self.entity, "can_spawn_treasure", 1 )
		end	
	elseif ( markerName == "spawn_treasure" ) then
		local ent = EntityService:SpawnEntity( self.data:GetString( "spawn_treasure_bp" ), self.entity, "att_spawn", "player" )
		EntityService:ChangeToDynamic( ent, "default", "wreck", 3, 400, 5.0, 0.5 )
		UnitService:SetStateMachineParam( self.entity, "can_spawn_treasure", 0 )
	end

	return true
end

return poogret
