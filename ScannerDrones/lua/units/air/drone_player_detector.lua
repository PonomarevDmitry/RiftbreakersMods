local base_drone = require("lua/units/air/base_drone.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/find_utils.lua")

class 'drone_player_detector' ( base_drone )

function drone_player_detector:__init()
	base_drone.__init(self,self)
end

function drone_player_detector:OnInit()
	self:FillInitialParams()
end

function drone_player_detector:OnLoad()

	self:FillInitialParams()

	if ( base_drone.OnLoad ) then
		base_drone.OnLoad( self )
	end
end

function drone_player_detector:FillInitialParams()

	if self.data:HasFloat("drone_search_radius") then
		self.search_radius = self.data:GetFloat("drone_search_radius")
	else
		self.search_radius = self.data:GetFloat("search_radius")
	end

	self.radius = self.data:GetFloat( "radius" )
	self.enemyRadius = self.data:GetFloat( "enemy_radius" )
	self.level = self.data:GetInt( "lvl" )

	if ( self.effectScanner ~= nil and self.effectScanner ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.effectScanner )
	end

	self.effect = INVALID_ID
	self.effectScanner = INVALID_ID

	self.type = ""
	self.lastFactor = 0

	EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", 1 )

	self.effectScanner = EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner", self.entity, "att_detector", "" )
	EntityService:SetScale( self.effectScanner, 15.0, 15.0, 15.0 )

	EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )

	if ( self.fsmFollow == nil ) then
		self.fsmFollow = self:CreateStateMachine();
		self.fsmFollow:AddState("follow", { execute="OnFollowExecute" } )
	end

	if ( self.fsmDetect == nil ) then
		self.fsmDetect = self:CreateStateMachine()
		self.fsmDetect:AddState( "working", { execute="OnWorkInProgress" } )
	end

	if ( self.fsmHarvest == nil ) then
		self.fsmHarvest = self:CreateStateMachine()
		self.fsmHarvest:AddState( "harvest", { enter="OnHarvestEnter", execute="OnHarvestExecute", interval=0.1 } )
	end

	self.fsmDetect:ChangeState("working")
end

function drone_player_detector:OnWorkInProgress()

	local owner = self:GetDroneOwnerTarget()

	local predicate = {

		signature = "TreasureComponent",

		filter = function( entity )

			local treasureComponent = EntityService:GetComponent( entity, "TreasureComponent")
			if ( treasureComponent:GetField("is_discovered"):GetValue() == "1" ) then
				return false
			end

			if ( tonumber(treasureComponent:GetField("lvl"):GetValue()) > self.level ) then
				return false
			end

			local db = EntityService:GetDatabase( entity )
			if ( db == nil ) then
				return false
			end

			local type = db:GetStringOrDefault("type","")
			if ( type ~= "enemy") then
				return false
			end

			return true
		end
	}

	local enemyEntities = FindService:FindEntitiesByPredicateInRadius( owner, self.enemyRadius, predicate );

	local foundNormal = ItemService:FindClosestTreasureInRadius( owner, self.level, "", "enemy" )
	local ent = foundNormal.first
	local distance = foundNormal.second

	local foundEnemy = FindClosestEntityWithDistance( self.entity, enemyEntities )
	local entEnemy = foundEnemy.entity
	local distanceEnemy = foundEnemy.distance

	if ( (ent ~= INVALID_ID ) or (entEnemy ~= INVALID_ID and self.enemyRadius > distanceEnemy) ) then

		local type = ""

		local radius = self.radius
		if ( distanceEnemy ~= nil and distanceEnemy < distance and self.enemyRadius > distanceEnemy ) then
			ent = entEnemy
			distance = distanceEnemy
			type = "enemy"
			radius = self.enemyRadius
		end

		local discoverDistance = self:GetDiscoveryDistance( ent )

		local distanceToSelf = EntityService:GetDistance2DBetween( self.entity, ent )

		local factor = (distanceToSelf - discoverDistance) / ( radius - discoverDistance )

		if ( distance > discoverDistance or type == "enemy" ) then

			local mode = self:CheckAndSpawnEffect( ent, type, factor )
			self.lastFactor = factor;

			local itemPos = EntityService:GetPosition( self.effectScanner )
			local targetPos = EntityService:GetPosition( ent )

			EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 1 )
			EntityService:SetGraphicsUniform( self.effectScanner, "cTargetPos", targetPos.x, targetPos.y, targetPos.z )
			EntityService:SetGraphicsUniform( self.effectScanner, "cCenterPos", itemPos.x, itemPos.y, itemPos.z )
			EntityService:SetGraphicsUniform( self.effectScanner, "cRadius", radius )

			local noSound = (mod_scanner_drone_no_sound and mod_scanner_drone_no_sound == 1)

			if type == "enemy" then

				if ( not noSound ) then
					PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_geoscanner_trap.wav", true, 5 )
				end
				
				EntityService:SetGraphicsUniform( self.effectScanner, "cIsEnemy", 1 )
			else

				if ( not noSound ) then
					PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_geoscanner_treasure.wav", true, 5 )
				end

				EntityService:SetGraphicsUniform( self.effectScanner, "cIsEnemy", 0 )
			end

			if ( not noSound ) then
				if ( self.effect ~= INVALID_ID and self.effect ~= nil ) then
					if ( mode > 2 ) then

						factor = Clamp(factor, 0.0, 0.999)

						SoundService:SetSynthParam( self.effect, "latency", 1.0 / ( 1.0 - factor ) / 25.0 )
					else
						SoundService:SetSynthParam( self.effect, "latency", 1.0 )
					end
				end
			end

			if ( type ~= "enemy") then
				return
			end
		end

		if ( type == "enemy") then

			for eEnt in Iter( enemyEntities ) do

				local eDistance = EntityService:GetDistanceBetween( eEnt, self.entity )

				local discoverDistance = self:GetDiscoveryDistance( eEnt )

				if ( eDistance <= discoverDistance ) then
					ItemService:RevealHiddenEntity( eEnt )
				end
			end
		end

	else

		EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )

		if ( self.effect ~= INVALID_ID and self.effect ~= nil ) then
			EntityService:RemoveEntity( self.effect )
		end
		self.effect = INVALID_ID

		self.type = ""
		self.lastFactor = -1
	end
end

function drone_player_detector:GetDiscoveryDistance( entity )

	local discoverDistance = 10

	local db = EntityService:GetDatabase( entity )

	if ( db ~= nil and db:HasFloat("discovery_distance") ) then
		discoverDistance = db:GetFloat("discovery_distance")
	end

	return discoverDistance
end

function drone_player_detector:FindActionTarget()

	self:DestroyLightningEntity()
	self.fsmHarvest:Deactivate()
	self.fsmFollow:Deactivate()

	local result = self:FindNearestTreaure()

	self.fsmFollow:ChangeState("follow")

	return result
end

function drone_player_detector:FindNearestTreaure()

	local owner = self:GetDroneOwnerTarget()

	local predicate = {

		signature = "TreasureComponent",

		filter = function( entity )

			local treasureComponent = EntityService:GetComponent( entity, "TreasureComponent")
			if ( treasureComponent:GetField("is_discovered"):GetValue() == "1" ) then
				return false
			end

			if ( tonumber(treasureComponent:GetField("lvl"):GetValue()) > self.level ) then
				return false
			end

			local db = EntityService:GetDatabase( entity )
			if ( db == nil ) then
				return false
			end

			local type = db:GetStringOrDefault("type","")
			if ( type ~= "enemy") then
				return false
			end

			return true
		end
	}

	local enemyEntities = FindService:FindEntitiesByPredicateInRadius( owner, self.enemyRadius, predicate );

	local foundNormal = ItemService:FindClosestTreasureInRadius( owner, self.level, "", "enemy" )
	local ent = foundNormal.first
	local distance = foundNormal.second

	local foundEnemy = FindClosestEntityWithDistance( self.entity, enemyEntities )
	local entEnemy = foundEnemy.entity
	local distanceEnemy = foundEnemy.distance

	if ( (ent ~= INVALID_ID ) or (entEnemy ~= INVALID_ID and self.enemyRadius > distanceEnemy) ) then

		local type = ""

		if ( distanceEnemy ~= nil and distanceEnemy < distance and self.enemyRadius > distanceEnemy ) then
			ent = entEnemy
			distance = distanceEnemy
			type = "enemy"
		end

		if ( distance <= self.search_radius ) then

			if ( not self:IsDiscovered( ent ) ) then

				return ent
			end
		end
	end

	return INVALID_ID
end

function drone_player_detector:OnDroneTargetAction( target )

	if ( target == INVALID_ID ) then
		return
	end

	if ( not EntityService:IsAlive(target) ) then

		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self.fsmFollow:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return
	end

	local type = ""

	local db = EntityService:GetDatabase( target )
	if ( db ~= nil ) then
		type = db:GetStringOrDefault("type","")
	end

	if ( type == "enemy") then

		self.fsmHarvest:ChangeState("harvest")
	else

		if ( self:IsDiscovered( target ) ) then

			self:DestroyLightningEntity()
			self.fsmHarvest:Deactivate()
			self.fsmFollow:Deactivate()
			self:SetTargetActionFinished()
			self:TryFindNewTarget()

			return
		end
	end

	self.fsmFollow:ChangeState("follow")
end

function drone_player_detector:OnHarvestEnter()

	local target = self:GetDroneActionTarget()

	local database = EntityService:GetDatabase( target )

	local duration = 2.0
	if ( database ~= nil ) then
		duration =  database:GetFloatOrDefault("harvest_duration", 2.0 )
	end

	local lightning_effect = self.data:GetStringOrDefault("lightning_effect", "effects/buildings_and_machines/drone_defensive_lightning")
	local lightning_hit_effect = self.data:GetStringOrDefault("lightning_hit_effect", "effects/buildings_and_machines/drone_defensive_lightning_hit")

	self:DestroyLightningEntity()

	self.lightningEntity = EntityService:SpawnEntity( lightning_effect, self.entity, "")

	EntityService:CreateOrSetLifetime( self.lightningEntity, duration, "normal" )

	local component = reflection_helper(EntityService:GetComponent(self.lightningEntity, "LightningComponent"))

	local container = rawget(component.lighning_vec, "__ptr");
	local instance =  reflection_helper(container:CreateItem())

	local drone_position = EntityService:GetPosition(self.entity)
	local target_position = EntityService:GetPosition(target)

	local direction = VectorMulByNumber( Normalize( VectorSub( target_position, drone_position ) ), 2.0 )
	drone_position = VectorAdd(drone_position, direction)

	instance.start_point.x = drone_position.x
	instance.start_point.y = drone_position.y
	instance.start_point.z = drone_position.z

	instance.end_point.x = target_position.x
	instance.end_point.y = target_position.y
	instance.end_point.z = target_position.z

	EntityService:SpawnEntity( lightning_hit_effect, drone_position.x, drone_position.y, drone_position.z, "")
end

function drone_player_detector:OnHarvestExecute(state, dt)

	local target = self:GetDroneActionTarget()

	if ( target == INVALID_ID ) then
		self:DestroyLightningEntity()
		return state:Exit()
	end

	if ( not EntityService:IsAlive(target) ) then
		self:DestroyLightningEntity()
		return state:Exit()
	end

	local database = EntityService:GetDatabase( target )
	local type = ""

	local duration = 2.0
	if ( database ~= nil ) then
		duration =  database:GetFloatOrDefault("harvest_duration", 2.0 )
		type = database:GetStringOrDefault("type","")
	end

	if ( type ~= "enemy") then
		self:DestroyLightningEntity()
		return state:Exit()
	end

	if ( state:GetDuration() >= duration ) then

		local owner = self:GetDroneOwnerTarget()
			
		ItemService:InteractWithEntity( target, owner )

		EffectService:AttachEffects( target, "treasure" )

		self:DestroyLightningEntity()
		return state:Exit()
	end
end

function drone_player_detector:DestroyLightningEntity()

	if ( self.lightningEntity ~= nil ) then
		EntityService:RemoveEntity(self.lightningEntity)
		self.lightningEntity = nil
	end
end

function drone_player_detector:TryFindNewTarget()
	local target = self:FindActionTarget();
	if target ~= INVALID_ID then
		UnitService:SetCurrentTarget( self.entity, "action", target );
		UnitService:EmitStateMachineParam(self.entity, "action_target_found")
		UnitService:SetStateMachineParam( self.entity, "action_target_valid", 1)

		self.fsmFollow:ChangeState("follow")
	end
end

function drone_player_detector:OnFollowExecute(state)

	local target = self:GetDroneActionTarget()

	if ( target == INVALID_ID ) then

		local exitValue = state:Exit()
		
		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return exitValue
	end

	if ( not EntityService:IsAlive(target) ) then
		local exitValue = state:Exit()
		
		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return exitValue
	end

	local owner = self:GetDroneOwnerTarget()

	if ( EntityService:GetDistance2DBetween( owner, target ) > ( self.search_radius * 1.1 ) ) then
		local exitValue = state:Exit()
		
		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return exitValue
	end

	if ( self:IsDiscovered( target ) ) then
		local exitValue = state:Exit()
		
		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return exitValue
	end

	local nearestTreaure = self:FindNearestTreaure()

	if	( nearestTreaure ~= target ) then
		local exitValue = state:Exit()
		
		self:DestroyLightningEntity()
		self.fsmHarvest:Deactivate()
		self:SetTargetActionFinished()
		self:TryFindNewTarget()

		return exitValue
	end
end

function drone_player_detector:IsDiscovered( target )

	local treasureComponent = EntityService:GetComponent( target, "TreasureComponent")
	if	( treasureComponent == nil ) then
		return true
	end

	if ( treasureComponent:GetField("is_discovered"):GetValue() == "1" ) then
		return true
	end

	return false
end

function drone_player_detector:GetModeFromFactor( factor )
	if ( factor > 2.0 ) then
		return 1
	elseif( factor > 1.0 ) then
		return 2
	else
		return 3
	end
end

function drone_player_detector:CheckAndSpawnEffect( ent, type, factor )

	local mode = self:GetModeFromFactor( factor )
	local oldMode = self:GetModeFromFactor( self.lastFactor )

	if ( type ~= self.type or mode ~= oldMode or ( ent ~= self.oldEnt and self.oldEnt ~= INVALID_ID ) ) then

		if ( self.effect ~= INVALID_ID and self.effect ~= nil ) then
			EntityService:RemoveEntity( self.effect )
		end
		self.effect = INVALID_ID
		self.type = ""
	end

	self.oldEnt = ent

	if( self.effect == nil or self.effect == INVALID_ID ) then
		self.type = type

		local effectName = "effects/mech/treasure_finder_beep_infinite"

		if ( type == "enemy" ) then
			effectName = "effects/mech/treasure_finder_beep_infinite_red"
		end

		local noSound = (mod_scanner_drone_no_sound and mod_scanner_drone_no_sound == 1)

		if ( noSound ) then
			if ( self.effect ~= INVALID_ID and self.effect ~= nil ) then
				EntityService:RemoveEntity( self.effect )
			end
			self.effect = INVALID_ID
		else

			self.effect = EntityService:SpawnAndAttachEntity( effectName, self.entity, "att_detector", "" )
		end

		if ( type == "enemy" ) then
			return 3
		end
	end

	return mode
end

function drone_player_detector:OnRelease()

	PlayerService:StopPadHapticFeedback( 0 )

	if ( self.effect ~= INVALID_ID and self.effect ~= nil ) then
		EntityService:RemoveEntity( self.effect )
	end
	self.effect = INVALID_ID

	if ( self.effectScanner ~= INVALID_ID and self.effectScanner ~= nil ) then
		EntityService:RemoveEntity( self.effectScanner )
	end
	self.effectScanner = INVALID_ID

	if ( self.lightningEntity ~= nil ) then
		EntityService:RemoveEntity(self.lightningEntity)
		self.lightningEntity = nil
	end

	if ( base_drone.OnRelease ) then
		base_drone.OnRelease(self)
	end
end

return drone_player_detector