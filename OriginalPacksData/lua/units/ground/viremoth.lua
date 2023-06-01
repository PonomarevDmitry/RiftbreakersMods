require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'viremoth' ( base_unit )

function viremoth:__init()
	base_unit.__init(self, self)
end

function viremoth:OnInit()
	
	self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )
	self:RegisterHandler( self.entity, "ShootLightningEvent",  "OnShootLightningEvent" )
	self:RegisterHandler( self.entity, "EnterStunEvent",  "OnEnterStunEvent" )
	self:RegisterHandler( self.entity, "ExitStunEvent",  "OnExitStunEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "logic", { enter="OnEnterLogic", execute="OnExecuteLogic" } )
	self.fsm:ChangeState( "logic" )

	self.fsmAlive = self:CreateStateMachine()
	self.fsmAlive:AddState( "alive", { execute="OnExecuteAlive", interval = 1.0 } )
	self.fsmAlive:ChangeState( "alive" )

	self.children = {}

	self.removeChildDistance = 20

	self.dealDamage = 25
	self.heal = 25
	self.childSpeed = 5.0

	self.damageDealTo  = {}
	self.healTo  = {}

	self.lightnings  = {}

	self.stormEffect = self.data:GetString( "storm_effect" )

	self.INVALID_ID = tostring( INVALID_ID )

	self.stormTimer = RandFloat( 1.0, 2.0 )

	self.createChildTimer = self.data:GetFloatOrDefault( "create_child_timer", 10.0 )
	self.childrenCount    = self.data:GetIntOrDefault( "children_count", 10 )

	self.isStunned = false

	self.healEffect = "time_damage_acid"
	self.dmgEffect = "leech"
end

function viremoth:CreateChild()
	local entity = EntityService:SpawnEntity( self.data:GetString( "child_bp" ), self.entity, "wave_enemy" )
	UnitService:SetInitialState( entity, UNIT_AGGRESSIVE )
	UnitService:SetNavMeshMoveToTarget( entity, self.entity )
	HealthService:SetHealth( entity, HealthService:GetMaxHealth( self.entity ) )
	QueueEvent( "SetBaseMovementDataRequest", entity, self.childSpeed, self.childSpeed )
	
	return entity;
end

function viremoth:OnEnterLogic( state )
	for i = 1, self.childrenCount do
		table.insert( self.children, self:CreateChild() )
	end

end

function viremoth:AddEntityToData( target )
	local entity = tonumber( target )

	if ( ( EntityService:GetTeam( "player" ) == EntityService:GetTeam( entity ) ) or ( EntityService:GetType( entity ) == "cavern_wall" ) ) then
		for i = 1, #self.damageDealTo, 1 do 
		
			if ( self.damageDealTo[i].entity == entity ) then
				self.damageDealTo[i].counter = self.damageDealTo[i].counter + 1 		
				return
			end
		end

		local dealTo = {}
		dealTo.entity = entity
		dealTo.counter  = 1

		table.insert( self.damageDealTo, dealTo )
	else
		for i = 1, #self.healTo, 1 do 
		
			if ( self.healTo[i].entity == entity ) then
				self.healTo[i].counter = self.healTo[i].counter + 1 		
				return
			end
		end

		local heal = {}
		heal.entity = entity
		heal.counter  = 1

		table.insert( self.healTo, heal )
	end
end

function viremoth:RemoveEntityFromData( target )
	local entity = tonumber( target )

	if ( ( EntityService:GetTeam( "player" ) == EntityService:GetTeam( entity ) ) or ( EntityService:GetType( entity ) == "cavern_wall" ) ) then
		for i = 1, #self.damageDealTo, 1 do  		
			if ( self.damageDealTo[i].entity == entity ) then
				self.damageDealTo[i].counter = self.damageDealTo[i].counter - 1 	
				if ( self.damageDealTo[i].counter == 0 ) then
					table.remove( self.damageDealTo, i )
					EffectService:DestroyEffectsByGroup( entity, self.dmgEffect );
					return
				end
			end
		end
	else
		for i = 1, #self.healTo, 1 do  		
			if ( self.healTo[i].entity == entity ) then
				self.healTo[i].counter = self.healTo[i].counter - 1 	
				if ( self.healTo[i].counter == 0 ) then
					EffectService:DestroyEffectsByGroup( entity, self.healEffect );
					table.remove( self.healTo, i )
					return
				end
			end
		end
	end
end

function viremoth:OnLuaGlobalEvent( evt )
	
	local params = evt:GetDatabase()
	local eventName = evt:GetEvent()

	local target = params:GetStringOrDefault( "target", self.INVALID_ID )

	if ( eventName == "ChildDealEvent" ) then
		self:AddEntityToData( target )
	elseif ( eventName == "ChildReleaseEvent" ) then
		self:RemoveEntityFromData( target )
	end
end

function viremoth:OnEnterStunEvent( evt )
	self.isStunned = true

	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i] ) == true ) then
		    QueueEvent( "SetBaseMovementDataRequest", self.children[i], 0.0, 0.0 )	
		end
	end
end

function viremoth:OnExitStunEvent( evt )
	self.isStunned = false

	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i] ) == true ) then
			QueueEvent( "SetBaseMovementDataRequest", self.children[i], self.childSpeed, self.childSpeed )	
		end
	end
end

function viremoth:OnEnteredTriggerEvent( evt )
	self:AddEntityToData( evt:GetOtherEntity() )
end

function viremoth:OnLeftTriggerEvent( evt )
	self:RemoveEntityFromData( evt:GetOtherEntity() )
end

function viremoth:OnExecuteAlive( state, dt )
	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i] ) == false ) then
			table.remove( self.children, i )
			break
		end
	end

	for i = 1, #self.children do	
		local distance = EntityService:GetDistanceBetween( self.entity, self.children[i] )
		if ( distance > self.removeChildDistance ) then
			EntityService:RemoveEntity( self.children[i] )	
			table.remove( self.children, i )
			table.insert( self.children, self:CreateChild() )
			break
		end
	end
end

function viremoth:OnExecuteLogic( state, dt )

	local removeChildren = {}

	if ( self.isStunned ~= true ) then
		for i = 1, #self.damageDealTo, 1 do  
			QueueEvent( "DamageWithOwnerRequest", self.damageDealTo[i].entity, self.dealDamage  * dt, "physical", 1, 0, self.entity, self.entity )
		
			if ( EffectService:HasEffectByGroup( self.damageDealTo[i].entity, self.dmgEffect ) == false ) then
				EffectService:AttachEffects( self.damageDealTo[i].entity, self.dmgEffect )
			end	
			--LogService:Log( "viremoth:damageDealTo - entity : " .. tostring(self.damageDealTo[i].entity ) )
			--LogService:Log( "viremoth:damageDealTo - counter : " .. tostring(self.damageDealTo[i].counter ) )
		end

		for i = 1, #self.healTo, 1 do  

			local health = HealthService:GetHealth( self.healTo[i].entity );
			local maxHealth = HealthService:GetMaxHealth( self.healTo[i].entity );	

			if ( health < maxHealth ) then
				health = health + self.heal  * dt
				HealthService:SetHealth( self.healTo[i].entity, math.min( health, maxHealth ) );

				if ( EffectService:HasEffectByGroup( self.healTo[i].entity, self.healEffect ) == false ) then
					EffectService:AttachEffects( self.healTo[i].entity, self.healEffect )
				end	
			else
				if ( EffectService:HasEffectByGroup( self.healTo[i].entity, self.healEffect ) == true ) then
					EffectService:DestroyEffectsByGroup( self.healTo[i].entity, self.healEffect )
				end		
			end
		

			--LogService:Log( "viremoth:healTo - entity : " .. tostring(self.healTo[i].entity ) .. " health : " .. tostring( health ) .. "/" .. tostring( maxHealth ) )
			--LogService:Log( "viremoth:healTo - counter : " .. tostring(self.healTo[i].counter ) )
		end

		for i = 1, #self.lightnings do	
			self.lightnings[i].timer = self.lightnings[i].timer - dt

			if ( self.lightnings[i].timer <= 0.0 ) then		
				local entity = EntityService:SpawnEntity( self.data:GetString( "bp_on_range_attack" ), self.lightnings[i].target.x, 50.0, self.lightnings[i].target.z, "enemy" )	
				EntityService:SetOrientation( entity, 0, 0, 1, -90 )
				table.remove( self.lightnings, i )
				break
			end
		end

		if ( UnitService:GetStateMachineParamInt( self.entity, "visible" ) == 1 ) then
			self.stormTimer = self.stormTimer - dt

			if ( self.stormTimer <= 0 ) then
				local count = RandInt( #self.children,  #self.children * 3 )

				local origins = EntityService:BuildConvexHullOrigins( self.children )

				if ( #origins >= 3 ) then		
					for i = 1, count, 1 do  
						self:CreateStorm( origins[RandInt( 1, #origins )], origins[RandInt( 1, #origins )] )
					end
				end
				self.stormTimer = RandFloat( 0.1, 0.5 )
			end
		end
		--LogService:Log( "viremoth:OnExecuteHandleChildren : " .. tostring(#self.children) )

		if ( #self.children < self.childrenCount ) then

			self.createChildTimer = self.createChildTimer - dt

			if ( self.createChildTimer <= 0 ) then
				table.insert( self.children, self:CreateChild() )
				self.createChildTimer = self.data:GetFloatOrDefault( "create_child_timer", 10.0 )
			end
		end
	end
end


function viremoth:CreateStorm( fromOrigin, toOrigin )
	local distance = Distance( fromOrigin, toOrigin )

	if ( distance > 10 ) then
		return
	end

    local lightning = EntityService:SpawnEntity( self.stormEffect, self.entity, "" )
    local component = reflection_helper( EntityService:GetComponent( lightning, "LightningComponent" ) )

    local container = rawget( component.lighning_vec, "__ptr" );
    local instance =  reflection_helper( container:CreateItem() )

    instance.start_point.x = fromOrigin.x
    instance.start_point.y = fromOrigin.y
    instance.start_point.z = fromOrigin.z

    instance.end_point.x = toOrigin.x
    instance.end_point.y = toOrigin.y + RandFloat( 2.0, 4.0 )
    instance.end_point.z = toOrigin.z

	EntityService:CreateLifeTime( lightning, RandFloat( 0.1, 0.4 ), "" )

end

function viremoth:OnShootLightningEvent( evt )
	
	local targetOrigin = UnitService:GetCurrentTargetAsOrigin( evt:GetEntity(), evt:GetTargetTag() )

	local count = self.data:GetIntOrDefault( "lightning_count", 1 )
	local lightningSpawnRadius = self.data:GetFloatOrDefault( "lightning_spawn_radius", 1 )
	local lightningDelayMinTime = self.data:GetFloatOrDefault( "lightning_delay_min_time",  0.5 )
	local lightningDelayMaxTime = self.data:GetFloatOrDefault( "lightning_delay_max_time",  0.5 )
	
	for i = 1, count do	
		
		local targetOriginOffset = {}
		
		targetOriginOffset.x = targetOrigin.x + RandFloat( -lightningSpawnRadius / 2.0, lightningSpawnRadius / 2.0 )
		targetOriginOffset.y = targetOrigin.y
		targetOriginOffset.z = targetOrigin.z + RandFloat( -lightningSpawnRadius / 2.0, lightningSpawnRadius / 2.0 )

		EntityService:SpawnEntity( self.data:GetString( "warning_effect_on_range_attack" ), targetOriginOffset.x, targetOriginOffset.y, targetOriginOffset.z, "" )	

		local lightning = {}
		lightning.target = targetOriginOffset
		lightning.timer  = RandFloat( lightningDelayMinTime, lightningDelayMaxTime )

		table.insert( self.lightnings, lightning )
	end
end

function viremoth:_OnDestroyRequest( state )

	for i = 1, #self.children do	
		EntityService:RemoveEntity( self.children[i] )	
	end

	for i = 1, #self.damageDealTo, 1 do  		
		EffectService:DestroyEffectsByGroup( self.damageDealTo[i].entity, self.dmgEffect );
	end

	for i = 1, #self.healTo, 1 do  		
		EffectService:DestroyEffectsByGroup( self.healTo[i].entity, self.healEffect );
	end


	EntityService:RemoveEntity( self.entity )	
end

return viremoth
