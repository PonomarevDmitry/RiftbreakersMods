require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'swarm' ( base_unit )

function swarm:__init()
	base_unit.__init(self, self)
end

function swarm:OnInit()
	
	self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnLuaGlobalEvent" )
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )
	self:RegisterHandler( self.entity, "EnterStunEvent",  "OnEnterStunEvent" )
	self:RegisterHandler( self.entity, "ExitStunEvent",  "OnExitStunEvent" )

	self.createChildTimer = self.data:GetFloatOrDefault( "create_child_timer", 10.0 )

	self.fsmAlive = self:CreateStateMachine()
	self.fsmAlive:AddState( "alive", { execute="OnExecuteAlive", interval = self.createChildTimer } )
	self.fsmAlive:ChangeState( "alive" )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "prepare_logic", { enter="OnEnterPrepareLogic", exit="OnExitPrepareLogic" } )
	self.fsm:AddState( "logic", { enter="OnEnterLogic", execute="OnExecuteLogic" } )
	self.fsm:ChangeState( "prepare_logic" )

	self.children = {}

	self.removeChildDistance = 20

	self.dealDamage = 25
	self.heal = 25
	self.childSpeed = 7.0

	self.damageDealTo  = {}
	self.healTo  = {}

	self.INVALID_ID = tostring( INVALID_ID )
	
	self.childrenCount    = self.data:GetIntOrDefault( "children_count", 10 )

	self.isStunned = false

	self.healEffect = "healing" -- default
	self.dmgEffect = "leech" -- default

	self:_OnInit()
end

function swarm:GetRandomPositionOnBounds( radius )

    local angle = math.random() * 2 * math.pi  

    
	local origin = EntityService:GetPosition( self.entity )
	origin.x = origin.x + radius * math.cos( angle )
	origin.z = origin.z + radius * math.sin( angle )

    return { x = origin.x, y = origin.y, z = origin.z } 
end

function swarm:CreateChild()
	
	local originToSpawn = {}

	if EntityService:HasComponent( self.entity, "NavMeshMovementComponent" ) or EntityService:HasComponent( EntityService:GetParent( self.entity ), "NavMeshMovementComponent" ) then
		originToSpawn = EntityService:GetPosition( self.entity )
	else
		local boundsEntity = EntityService:GetParent( self.entity )

		if ( boundsEntity == INVALID_ID ) then
			boundsEntity = self.entity
		end	

		local size = EntityService:GetBoundsSize( boundsEntity )
		originToSpawn = self:GetRandomPositionOnBounds( Length( size ) * 0.25 )
	end

	local entity = EntityService:SpawnEntity( self.data:GetString( "child_bp" ), originToSpawn.x, originToSpawn.y, originToSpawn.z, "wave_enemy" )
	UnitService:SetInitialState( entity, UNIT_AGGRESSIVE )
	UnitService:SetNavMeshMoveToTarget( entity, self.entity )
	QueueEvent( "SetBaseMovementDataRequest", entity, self.childSpeed, self.childSpeed )
	
	 if ( self._CreateChild ) then
		self:_CreateChild( entity )
	 end

	return entity;
end

function swarm:OnEnterPrepareLogic( state )
	state:SetDurationLimit( 0.1 )
end

function swarm:OnExitPrepareLogic( state )
	self.fsm:ChangeState( "logic" )
end

function swarm:OnEnterLogic( state )
	for i = 1, self.childrenCount do
		local child = {}
		child.entity = self:CreateChild()
		child.currentHeight  = 0
		
		table.insert( self.children, child )
	end

end

function swarm:AddEntityToData( target )
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

function swarm:RemoveEntityFromData( target )
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

function swarm:OnLuaGlobalEvent( evt )
	
	local params = evt:GetDatabase()
	local eventName = evt:GetEvent()

	local target = params:GetStringOrDefault( "target", self.INVALID_ID )

	if ( eventName == "ChildDealEvent" ) then
		self:AddEntityToData( target )
	elseif ( eventName == "ChildReleaseEvent" ) then
		self:RemoveEntityFromData( target )
	end
end

function swarm:OnEnterStunEvent( evt )
	self.isStunned = true

	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i].entity ) == true ) then
		    QueueEvent( "SetBaseMovementDataRequest", self.children[i].entity, 0.0, 0.0 )	
		end
	end
end

function swarm:OnExitStunEvent( evt )
	self.isStunned = false

	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i].entity ) == true ) then
			QueueEvent( "SetBaseMovementDataRequest", self.children[i].entity, self.childSpeed, self.childSpeed )	
		end
	end
end

function swarm:OnEnteredTriggerEvent( evt )
	self:AddEntityToData( evt:GetOtherEntity() )
end

function swarm:OnLeftTriggerEvent( evt )
	self:RemoveEntityFromData( evt:GetOtherEntity() )
end

function swarm:OnExecuteAlive( state, dt )
	for i = 1, #self.children do	
		if ( EntityService:IsAlive( self.children[i].entity ) == false ) then
			table.remove( self.children, i )
			break
		end
	end

	for i = 1, #self.children do	
		local distance = EntityService:GetDistanceBetween( self.entity, self.children[i].entity )
		if ( distance > self.removeChildDistance ) then
			EntityService:RemoveEntity( self.children[i].entity )	
			table.remove( self.children, i )

			local child = {}
			child.entity = self:CreateChild()
			child.currentHeight  = 0

			table.insert( self.children, child )
			break
		end
	end
end

function swarm:OnExecuteLogic( state, dt )
	self:_OnExecuteLogic( state, dt )
end


function swarm:CreateStorm( fromOrigin, toOrigin )
	local distance = Distance( fromOrigin, toOrigin )

	if ( distance > 10 ) then
		return
	end

    local lightning = EntityService:SpawnEntity( self.stormEffect, self.entity, "" )
    local component = reflection_helper( EntityService:GetComponent( lightning, "LightningDataComponent" ) )

    local container = rawget( component.lighning_vec, "__ptr" );
    local instance = nil
    if ( container:GetItemCount() == 0 ) then
        instance = reflection_helper(container:CreateItem())
    else 
        instance = reflection_helper(container:GetItem(0))
    end

    instance.start_point.x = fromOrigin.x
    instance.start_point.y = fromOrigin.y
    instance.start_point.z = fromOrigin.z

    instance.end_point.x = toOrigin.x
    instance.end_point.y = toOrigin.y + RandFloat( 2.0, 4.0 )
    instance.end_point.z = toOrigin.z

	EntityService:CreateLifeTime( lightning, RandFloat( 0.1, 0.4 ), "" )

end



function swarm:_OnDestroyRequest( evt )
	for i = 1, #self.children do	
		EntityService:RequestDestroyPattern( self.children[i].entity, "wreck" )
	end

    if self.__OnDestroyRequest then
        self:__OnDestroyRequest( evt )
	else
		for i = 1, #self.damageDealTo, 1 do  		
			EffectService:DestroyEffectsByGroup( self.damageDealTo[i].entity, self.dmgEffect );
		end

		for i = 1, #self.healTo, 1 do  		
			EffectService:DestroyEffectsByGroup( self.healTo[i].entity, self.healEffect );
		end

		EntityService:RequestDestroyPattern( self.entity, "wreck" )	
    end
end

return swarm
