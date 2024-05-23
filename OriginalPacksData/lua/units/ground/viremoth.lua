require("lua/utils/table_utils.lua")

local swarm = require("lua/units/ground/swarm.lua")
class 'viremoth' ( swarm )

function viremoth:__init()
	swarm.__init(self, self)
end

function viremoth:_OnInit()
	

	self:RegisterHandler( self.entity, "ShootLightningEvent",  "OnShootLightningEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	self.lightnings  = {}

	self.stormEffect = self.data:GetString( "storm_effect" )
	self.stormTimer = RandFloat( 1.0, 2.0 )

	self.stormTimer = RandFloat( 1.0, 2.0 )

end

function viremoth:_OnExecuteLogic( state, dt )

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

				local convexEntities = {}

				for i = 1, #self.children do	
					table.insert( convexEntities, self.children[i].entity )
				end

				local origins = EntityService:BuildConvexHullOrigins( convexEntities )

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
				local child = {}
				child.entity = self:CreateChild()
				child.currentHeight  = 0

				table.insert( self.children, child )
				self.createChildTimer = self.data:GetFloatOrDefault( "create_child_timer", 10.0 )
			end
		end
	end
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

return viremoth
