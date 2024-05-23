local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/find_utils.lua")

class 'detector' ( item )

function detector:__init()
	item.__init(self)
end

function detector:OnInit()
	self.radius   = self.data:GetFloat( "radius" )
	self.enemyRadius   = self.data:GetFloat( "enemy_radius" )
	self.level    = self.data:GetInt( "lvl" )
	self.cooldown = 0.05
	self.timer = 0
	self.effect = INVALID_ID
	self.effectScanner = INVALID_ID
	self.type = ""
	self.lastItemEnt = nil
	self.poseType = ""
	self.lastItemType = ""
	self.lastFactor = 0
end

function detector:OnEquipped()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
	self.effectScanner =  EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner",  self.item, "att_detector", "" )
	EntityService:SetScale( self.effectScanner, 15.0, 15.0, 15.0 )
	EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )
end

function detector:OnActivate()
	PlayerService:SetPadHapticFeedback( 0, "sound/samples/haptic/interactive_geoscanner_treasure.wav", true, 5 )
	self:OnExecuteDetecting()
	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated()  ) then
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		QueueEvent("FadeEntityOutRequest", self.lastItemEnt, 0.5)
		EntityService:FadeEntity( self.item, DD_FADE_IN, 0.5 )
		self.lastItemType = ownerData:GetStringOrDefault( "RIGHT_HAND_item_type", "" )
		self.poseType = ownerData:GetStringOrDefault( "RIGHT_HAND_pose_type", "" )
	end
	ownerData:SetString( "RIGHT_HAND_item_type", "range_weapon" )

end

function detector:OnDeactivate( forced )
	PlayerService:StopPadHapticFeedback( 0 )

	EntityService:RemoveEntity( self.effect )
	EntityService:SetGraphicsUniform( self.effectScanner, "cAlpha", 0 )
	self.effect = INVALID_ID
	local ownerData = EntityService:GetDatabase( self.owner );
	if ownerData ~= nil then
		ownerData:SetString( "RIGHT_HAND_item_type", self.lastItemType )
		if self.poseType ~= "" then
			ownerData:SetString( "RIGHT_HAND_pose_type", self.poseType )
		end
		ownerData:SetFloat( "RIGHT_HAND_use_speed", 0 );
	end

	if (forced == false and  self.lastItemEnt ~= nil and EntityService:IsAlive( self.lastItemEnt ) ) then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.5 )
	end
	QueueEvent("FadeEntityOutRequest", self.item, 0.5)
	self.lastItemEnt = nil
	return true
end

function GetModeFromFactor( factor )
	if ( factor > 2.0 ) then
		return 1
	elseif( factor > 1.0 ) then
		return 2
	else
		return 3
	end
end

function detector:CheckAndSpawnEffect( ent, type, factor)
	local mode = GetModeFromFactor( factor )
	local oldMode = GetModeFromFactor( self.lastFactor )
	--LogService:Log(tostring(mode) .. ":" .. tostring(oldMode))
	if ( type ~= self.type or mode ~= oldMode or ( ent ~= self.oldEnt and self.oldEnt ~= INVALID_ID ) ) then
		EntityService:RemoveEntity( self.effect )
		self.effect  = INVALID_ID
	--LogService:Log("remove")
	self.type = ""
	end

	self.oldEnt = ent
	--LogService:Log("Will spawn? " .. tostring(self.effect) )
	
	if( self.effect == nil or self.effect == INVALID_ID ) then
		self.type = type

		if ( type == "enemy" ) then
			--LogService:Log("enemy")
			self.effect = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite_red",  self.item, "att_detector", "" )
			return 3
		else
			--LogService:Log("normal")
			self.effect = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite",  self.item, "att_detector", "" )
		end
	end
	return mode
end

function detector:CanActivate()
	if MissionService.IsPlayerDetectorBlocked then
		return not MissionService:IsPlayerDetectorBlocked()
	end

	return true
end

function detector:OnExecuteDetecting()
	self.predicate = self.predicate or {
		signature = "TreasureComponent",
		filter = function( entity ) 
			local treasureComponent = EntityService:GetComponent( entity, "TreasureComponent")
			if ( treasureComponent:GetField("is_discovered"):GetValue() == "1" ) then
				return false
			end
			
			if (  tonumber(treasureComponent:GetField("lvl"):GetValue()) > self.level ) then
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

	local enemyEntities = FindService:FindEntitiesByPredicateInRadius( self.item, self.enemyRadius, self.predicate );

	local foundNormal = ItemService:FindClosestTreasureInRadius( self.item, self.level, "", "enemy" )
	local ent = foundNormal.first
	local distance = foundNormal.second

	local foundEnemy = FindClosestEntityWithDistance(self.item, enemyEntities)
	local entEnemy = foundEnemy.entity
	local distanceEnemy = foundEnemy.distance

	--LogService:Log( "EnemyEntitiesCount: ".. tostring(#enemyEntities) .. " EnemyEnt: "  .. tostring(entEnemy) .. ":" .. tostring(distanceEnemy))
	--LogService:Log( "NormalEnt: " .. tostring(ent) .. ":" .. tostring(distance))

	if ( (ent ~= INVALID_ID ) or (entEnemy ~= INVALID_ID and self.enemyRadius > distanceEnemy) ) then
		local type = ""

		local radius = self.radius
		if ( distanceEnemy ~= nil and distanceEnemy < distance and  self.enemyRadius > distanceEnemy ) then
			ent = entEnemy
			distance = distanceEnemy
			type = "enemy"
			--LogService:Log("enemy!")
			radius = self.enemyRadius
		end

		local db = EntityService:GetDatabase( ent )
		local discoverDistance = 10
		if ( db ~= nil and db:HasFloat("discovery_distance") ) then
			discoverDistance = db:GetFloat("discovery_distance")
		end

		local factor = (distance - discoverDistance)  / ( radius - discoverDistance )
		--LogService:Log("Factor: " .. tostring(factor) )
		--LogService:Log("DiscoverDistance: " .. tostring(discoverDistance) )

		if ( distance > discoverDistance or type == "enemy" ) then
			local mode = self:CheckAndSpawnEffect( ent, type, factor)
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
			for eEnt in Iter(enemyEntities ) do
				local eDistance = EntityService:GetDistanceBetween(eEnt, self.item)
				local db = EntityService:GetDatabase( eEnt )
				local discoverDistance = 10
				if ( db ~= nil and db:HasFloat("discovery_distance") ) then
					discoverDistance = db:GetFloat("discovery_distance")
				end
		
				if ( eDistance <= discoverDistance ) then
					ItemService:RevealHiddenEntity( eEnt )
				end
			end
		else
			ItemService:RevealHiddenEntity( ent )
		end
	
	elseif ( self.effect ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.effect )
		self.effect  = INVALID_ID
		self.type = ""
		self.lastFactor = -1;
	end
end

function detector:DissolveShow()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

return detector
