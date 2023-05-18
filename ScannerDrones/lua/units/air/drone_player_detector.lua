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

	base_drone.OnLoad( self )
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

	self.effect = INVALID_ID
	self.effectScanner = INVALID_ID

	self.type = ""
	self.lastFactor = 0

	EntityService:SetGraphicsUniform( self.entity, "cDissolveAmount", 1 )

	self.effectScanner = EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner", self.entity, "att_detector", "" )
	EntityService:SetScale( self.effectScanner, 15.0, 15.0, 15.0 )

	EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )

	self.fsmFollow = self:CreateStateMachine();
	self.fsmFollow:AddState("follow", { execute="OnFollowExecute" } )

	self.fsmDetect = self:CreateStateMachine()
	self.fsmDetect:AddState( "working", { execute="OnWorkInProgress" } )

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

	local foundEnemy = FindClosestEntityWithDistance( owner, enemyEntities )
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

			if type == "enemy" then
				PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_geoscanner_trap.wav", true, 5 )
				EntityService:SetGraphicsUniform( self.effectScanner, "cIsEnemy", 1 )
			else
				PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_geoscanner_treasure.wav", true, 5 )
				EntityService:SetGraphicsUniform( self.effectScanner, "cIsEnemy", 0 )
			end

			if ( mode > 2 ) then

				factor = Clamp(factor, 0.0, 0.999)

				SoundService:SetSynthParam( self.effect, "latency", 1.0 / ( 1.0 - factor ) / 25.0 )
			else
				SoundService:SetSynthParam( self.effect, "latency", 1.0 )
			end

			if ( type ~= "enemy") then
				return
			end
		end
		
		if ( type == "enemy") then

			for eEnt in Iter( enemyEntities ) do

				local eDistance = EntityService:GetDistanceBetween( eEnt, owner )

				local discoverDistance = self:GetDiscoveryDistance( eEnt )
		
				if ( eDistance <= discoverDistance ) then
					ItemService:RevealHiddenEntity( eEnt )
				end
			end
		end
	
	else

		EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )

		if ( self.effect ~= INVALID_ID ) then

			EntityService:RemoveEntity( self.effect )
			self.effect = INVALID_ID

			self.type = ""
			self.lastFactor = -1;
		end
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

	local foundEnemy = FindClosestEntityWithDistance( owner, enemyEntities )
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

		self.fsmFollow:Deactivate()
		self:SetTargetActionFinished()
		self.fsmFollow:ChangeState("follow")

		return
	end

	if ( self:IsDiscovered( target ) ) then

		self.fsmFollow:Deactivate()
		self:SetTargetActionFinished()
		self.fsmFollow:ChangeState("follow")

		return
	end

	self.fsmFollow:ChangeState("follow")
end

function drone_player_detector:OnFollowExecute(state)

	local target = self:GetDroneActionTarget()

	if ( target == INVALID_ID ) then
		self:SetTargetActionFinished()
		return state:Exit()
	end

	if ( not EntityService:IsAlive(target) ) then
		self:SetTargetActionFinished()
		return state:Exit()
	end

	local owner = self:GetDroneOwnerTarget()

	if ( EntityService:GetDistance2DBetween( owner, target ) > ( self.search_radius * 1.1 ) ) then
		self:SetTargetActionFinished()
		return state:Exit()
	end

	if ( self:IsDiscovered( target ) ) then
		self:SetTargetActionFinished()
		state:Exit()
	end

	local nearestTreaure = self:FindNearestTreaure()

	if	( nearestTreaure ~= target ) then
		self:SetTargetActionFinished()
		state:Exit()
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
		EntityService:RemoveEntity( self.effect )
		self.effect = INVALID_ID
		self.type = ""
	end

	self.oldEnt = ent
	
	if( self.effect == nil or self.effect == INVALID_ID ) then
		self.type = type

		if ( type == "enemy" ) then
			self.effect = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite_red", self.entity, "att_detector", "" )
			return 3
		else
			self.effect = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite", self.entity, "att_detector", "" )
		end
	end

	return mode
end

function drone_player_detector:OnRelease()

	PlayerService:StopPadHapticFeedback( 0 )

	EntityService:RemoveEntity( self.effect )
	self.effect = INVALID_ID

	EntityService:RemoveEntity( self.effectScanner )
	self.effectScanner = INVALID_ID
	
	if ( base_drone.OnRelease ) then
		base_drone.OnRelease(self)
	end
end

return drone_player_detector