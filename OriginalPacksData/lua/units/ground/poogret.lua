require ("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'poogret' ( base_unit )

function poogret:__init()
	base_unit.__init(self, self)
end

function poogret:OnInit()
	self.wreck_type = "wreck_small";
	self.wreckMinSpeed = 8
	self.currentFood = INVALID_ID

	UnitService:SetStateMachineParam( self.entity, "can_spawn_treasure", 0 )

	self:RegisterHandler( self.entity, "StartLeechEvent",  "OnStartLeechEvent" )
end

function poogret:OnStartLeechEvent( evt )

	LogService:Log( "poogret:OnStartLeechEvent()" )
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
