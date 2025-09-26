local item = require("lua/items/weapons/autofire_weapon.lua")

class 'scanner' ( item )

function scanner:__init()
	item.__init(self)
end

function scanner:OnInit()
	item.OnInit( self )
	
	self.maxScanTime = self.data:GetFloatOrDefault( "scanning_time", 10 )
	self.lastTarget = INVALID_ID
	self.effect 	= INVALID_ID
	self.scanningTime = 0.0
	self.lastItemEnt = nil


	-- Detector Part Start

	local blueprintDatabase = EntityService:GetBlueprintDatabase( "items/interactive/detector_item" )

	self.radiusDetector   = blueprintDatabase:GetFloat( "radius" )
	self.enemyRadiusDetector   = blueprintDatabase:GetFloat( "enemy_radius" )
	self.levelDetector    = blueprintDatabase:GetInt( "lvl" )
	self.effectDetector = INVALID_ID
	self.effectScannerDetector = INVALID_ID
	self.lastFactor = 0

	if ( self.effectScannerDetector == nil or self.effectScannerDetector == INVALID_ID or not EntityService:IsAlive( self.effectScannerDetector ) ) then
		self.effectScannerDetector =  EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner",  self.item, "att_muzzle_1", "" )
	end

	-- Detector Part End
end

function scanner:OnLoad()

	if ( item.OnLoad ) then
		item.OnLoad( self )
	end

	-- Detector Part Start

	local blueprintDatabase = EntityService:GetBlueprintDatabase( "items/interactive/detector_item" )

	self.radiusDetector   = blueprintDatabase:GetFloat( "radius" )
	self.enemyRadiusDetector   = blueprintDatabase:GetFloat( "enemy_radius" )
	self.levelDetector    = blueprintDatabase:GetInt( "lvl" )
	self.lastFactor = self.lastFactor or 0

	if ( self.effectScannerDetector == nil or self.effectScannerDetector == INVALID_ID or not EntityService:IsAlive( self.effectScannerDetector ) ) then
		self.effectScannerDetector =  EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner",  self.item, "att_muzzle_1", "" )
	end

	-- Detector Part End
end

function scanner:OnEquipped()
	item.OnEquipped( self ) 

	-- Detector Part Start

	if ( self.effectScannerDetector == nil or self.effectScannerDetector == INVALID_ID or not EntityService:IsAlive( self.effectScannerDetector ) ) then
		self.effectScannerDetector =  EntityService:SpawnAndAttachEntity( "items/interactive/detector_scanner",  self.item, "att_muzzle_1", "" )
	end
	EntityService:SetScale( self.effectScannerDetector, 15.0, 15.0, 15.0 )
	EntityService:SetGraphicsUniform( self.effectScannerDetector, "cAlpha", 0 )

	-- Detector Part End

	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

function scanner:OnUnequipped()
	item.OnUnequipped( self ) 
end

function scanner:OnActivate( activation_id )
	item.OnActivate( self, activation_id )
	self:OnExecuteScaning()

	QueueEvent("ShowScannableRequest", self.owner, true )

	-- Detector Part Start

	local isPlayerDetectorBlocked = false

	if ( MissionService.IsPlayerDetectorBlocked ) then
		isPlayerDetectorBlocked = MissionService:IsPlayerDetectorBlocked()
	end

	if ( isPlayerDetectorBlocked ) then

		if ( self.effectDetector ~= nil and self.effectDetector ~= INVALID_ID )  then
			EntityService:RemoveEntity( self.effectDetector )
		end
		self.effectDetector = INVALID_ID

		if ( self.effectScannerDetector ~= nil and self.effectScannerDetector ~= INVALID_ID ) then
			EntityService:SetGraphicsUniform( self.effectScannerDetector, "cAlpha", 0 )
		end

	else

		local playerId = PlayerService:GetPlayerForEntity(self.owner )
		PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_geoscanner_treasure.wav", true, 5 )

		self:OnExecuteDetecting()
	end

	-- Detector Part End

	local ownerData = EntityService:GetDatabase( self.owner );
	if ( not self:IsActivated() ) then
		self.lastItemEnt = ItemService:GetEquippedPresentationItem( self.owner, "RIGHT_HAND" )
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_OUT, 0.5 )
		EntityService:FadeEntity( self.item, DD_FADE_IN, 0.5 )
	end
	
	if ( ownerData ~= nil ) then
		ownerData:SetString( "RIGHT_HAND_item_type", "range_weapon" )
	end
end

function scanner:OnDeactivate( forced )
	local playerId = PlayerService:GetPlayerForEntity(self.owner )
	PlayerService:StopPadHapticFeedback( playerId )

	if not ( mod_combo_scanner_not_hide_scannable and mod_combo_scanner_not_hide_scannable == 1 ) then
		QueueEvent("ShowScannableRequest", self.owner, false )
	end
	
	if ( self.effect ~= INVALID_ID )  then
		EntityService:RemoveEntity( self.effect )
		self.effect = INVALID_ID
	end

	-- Detector Part Start
	
	if ( self.effectDetector ~= nil and self.effectDetector ~= INVALID_ID )  then
		EntityService:RemoveEntity( self.effectDetector )
	end
	self.effectDetector = INVALID_ID

	if ( self.effectScannerDetector ~= nil and self.effectScannerDetector ~= INVALID_ID ) then
		EntityService:SetGraphicsUniform( self.effectScannerDetector, "cAlpha", 0 )
	end

	-- Detector Part End

	self:RestoreSlotTypeAndPose("RIGHT_HAND", 0.0)

	if ( forced == false and  self.lastItemEnt ~= nil and EntityService:IsAlive( self.lastItemEnt ) ) then
		EntityService:FadeEntity( self.lastItemEnt, DD_FADE_IN, 0.5 )
	end

	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.5 )

	if ( self.lastTarget ~= INVALID_ID ) then 
		QueueEvent( "EntityScanningEndEvent", self.lastTarget )
	end
	
	self.lastItemEnt = nil
	self.lastTarget = INVALID_ID
	return item.OnDeactivate( self )
end

function scanner:SpawnSpecifcEffect( currentTarget )
	local effect
	local size = EntityService:GetBoundsSize( currentTarget )
		
	--LogService:Log( tostring( size.x ) ) 
	if ( size.x <= 2.5 ) then
		effect = "effects/mech/scanner_small"
	elseif ( size.x <= 4.5 ) then
		effect = "effects/mech/scanner"		
	elseif ( size.x <= 9.5 ) then
		effect = "effects/mech/scanner_big"		
	else
		effect = "effects/mech/scanner_very_big"		
	end
	
	self.effect = EntityService:SpawnAndAttachEntity( effect, currentTarget )
end

function scanner:OnExecuteScaning()
	local playerId = PlayerService:GetPlayerForEntity(self.owner )
	self.ammoEnt = EntityService:GetChildByName( self.item, "##ammo##" )
	if ( self.ammoEnt == nil or self.ammoEnt == INVALID_ID ) then
		-- Detector Part
		-- No BioScanner Sound
		--PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
		return	
	end
	
	local laserBeamComponent = EntityService:GetComponent( self.ammoEnt, "LaserBeamComponent")
	if ( laserBeamComponent ) then
		local currentTarget = tonumber(laserBeamComponent:GetField( "last_target" ):GetValue())
		
		if ( self.lastTarget ~= INVALID_ID and self.lastTarget ~= currentTarget ) then
			EntityService:RemoveEntity( self.effect )
			QueueEvent( "EntityScanningEndEvent", self.lastTarget )
			self.effect = INVALID_ID
			self.lastTarget = INVALID_ID
			self.scanningTime = 0.0
			
			-- Detector Part
			-- No BioScanner Sound
			--PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
			EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
		end
		
		if ( currentTarget ~= INVALID_ID ) then		
			local scannableComponent = EntityService:GetComponent( currentTarget, "ScannableComponent")
			if ( scannableComponent == nil ) then
				-- Detector Part
				-- No BioScanner Sound
				--PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
				EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
				return
			end
			local scannableComponentHelper = reflection_helper(scannableComponent)
			if ( self.effect == INVALID_ID ) then
				EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_active")
				-- Detector Part
				-- No BioScanner Sound
				--PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_scanning.wav", true, 5 )
				self.scanningTime = 0.0
				self:SpawnSpecifcEffect( currentTarget )
				QueueEvent( "EntityScanningStartEvent", currentTarget )
			elseif ( currentTarget == self.lastTarget ) then
				scannableComponentHelper.scanning_progress = scannableComponentHelper.scanning_progress + ( 1.0 / 30.0 ) 
				self.scanningTime = scannableComponentHelper.scanning_progress
				local factor =  self.scanningTime / self.maxScanTime
				factor = math.min(factor, 1.0 )
				EffectService:SetParticleEmmissionUniform( self.effect, factor )

				local maxScanTime = self.maxScanTime

				if ( mod_combo_scanner_instant_scan and mod_combo_scanner_instant_scan == 1 ) then
					maxScanTime = 0
				end

				if ( self.scanningTime >= maxScanTime ) then

					local scansCount = 1
					if ( mod_combo_scanner_size_matters and mod_combo_scanner_size_matters == 1 and ComboScannerSizeMattersGetScansCount ) then
						scansCount = ComboScannerSizeMattersGetScansCount(currentTarget)
					end

					for i=1,scansCount do
						ItemService:ScanEntity( currentTarget, self.owner )
					end

					EntityService:RemoveComponent( currentTarget, "ScannableComponent" ) 
					EntityService:RemoveEntity( self.effect )
					EffectService:DestroyEffectsByGroup( currentTarget, "scannable" )
					QueueEvent( "EntityScanningEndEvent", self.lastTarget )
					EffectService:SpawnEffect( currentTarget, "effects/loot/specimen_extracted")
					self.effect = INVALID_ID
					currentTarget = INVALID_ID
					self.scanningTime = 0.0
				end
			end
		end
		
		self.lastTarget = currentTarget;
	end
end

-- Detector Part Start

function scanner:GetModeFromFactor( factor )

	if ( factor == nil ) then
		factor = 0
	end

	if ( factor > 2.0 ) then
		return 1
	elseif( factor > 1.0 ) then
		return 2
	else
		return 3
	end
end

function scanner:CheckAndSpawnEffect( ent, type, factor)
	local mode = self:GetModeFromFactor( factor )
	local oldMode = self:GetModeFromFactor( self.lastFactor )
	if ( type ~= self.type ) then
		-- LogService:Log(tostring(mode) .. ":" .. tostring(oldMode))
		-- LogService:Log(type  .. ":" .. self.type)
		if ( self.effectDetector ~= nil and self.effectDetector ~= INVALID_ID )  then
			EntityService:RemoveEntity( self.effectDetector )
		end
		self.effectDetector  = INVALID_ID
		self.type = ""
	end

	self.oldEnt = ent
	--LogService:Log("Will spawn? " .. tostring(self.effectDetector) )
	
	if( self.effectDetector == nil or self.effectDetector == INVALID_ID ) then
		self.type = type

		if ( type == "enemy" ) then
			--LogService:Log("enemy")
			self.effectDetector = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite_red",  self.item, "att_muzzle_1", "" )
			return 3
		else
			--LogService:Log("normal")
			self.effectDetector = EntityService:SpawnAndAttachEntity( "effects/mech/treasure_finder_beep_infinite",  self.item, "att_muzzle_1", "" )
		end
	end
	return mode
end

function scanner:SetSynthParam( entity, synthParam, paramValue )
	--legacy: SoundService:SetSynthParam( self.effectDetector, synthParam, paramValue )
	if ( entity == nil or entity == INVALID_ID ) then
		return
	end

	local db = EntityService:GetOrCreateDatabase( entity )
	if ( db ~= nil ) then
		db:SetFloat( synthParam, paramValue );
	end
end

function scanner:OnExecuteDetecting()

	self.predicate = self.predicate or {

		signature = "TreasureComponent",
		filter = function( entity ) 
			local treasureComponent = EntityService:GetComponent( entity, "TreasureComponent")
			if ( treasureComponent:GetField("is_discovered"):GetValue() == "1" ) then
				return false
			end
			
			if (  tonumber(treasureComponent:GetField("lvl"):GetValue()) > self.levelDetector ) then
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

	local enemyEntities = FindService:FindEntitiesByPredicateInRadius( self.item, self.enemyRadiusDetector, self.predicate );

	local foundNormal = ItemService:FindClosestTreasureInRadius( self.item, self.levelDetector, "", "enemy" )
	local ent = foundNormal.first
	local distance = foundNormal.second

	local foundEnemy = FindClosestEntityWithDistance(self.item, enemyEntities)
	local entEnemy = foundEnemy.entity
	local distanceEnemy = foundEnemy.distance

	local defaultDiscoverDistance = 10

	if ( mod_default_discover_distance and type(mod_default_discover_distance) == "number" and mod_default_discover_distance > 0 ) then

		defaultDiscoverDistance = mod_default_discover_distance
	end

	--LogService:Log( "EnemyEntitiesCount: ".. tostring(#enemyEntities) .. " EnemyEnt: "  .. tostring(entEnemy) .. ":" .. tostring(distanceEnemy))
	--LogService:Log( "NormalEnt: " .. tostring(ent) .. ":" .. tostring(distance))

	if ( (ent ~= INVALID_ID ) or (entEnemy ~= INVALID_ID and self.enemyRadiusDetector > distanceEnemy) ) then
		local type = ""

		local radius = self.radiusDetector
		if ( distanceEnemy ~= nil and distanceEnemy < distance and  self.enemyRadiusDetector > distanceEnemy ) then
			ent = entEnemy
			distance = distanceEnemy
			type = "enemy"
			--LogService:Log("enemy!")
			radius = self.enemyRadiusDetector
		end

		local db = EntityService:GetDatabase( ent )
		local discoverDistance = defaultDiscoverDistance
		if ( db ~= nil and db:HasFloat("discovery_distance") ) then
			discoverDistance = db:GetFloat("discovery_distance")
		end

		local factor = (distance - discoverDistance)  / ( radius - discoverDistance )
		--LogService:Log("Factor: " .. tostring(factor) )
		--LogService:Log("DiscoverDistance: " .. tostring(discoverDistance) )

		if ( distance > discoverDistance or type == "enemy" ) then
			local mode = self:CheckAndSpawnEffect( ent, type, factor)
			self.lastFactor = factor;

			local itemPos = EntityService:GetPosition( self.effectScannerDetector )
			local targetPos = EntityService:GetPosition( ent )

			EntityService:SetGraphicsUniform( self.effectScannerDetector, "cAlpha", 1 )
			EntityService:SetGraphicsUniform( self.effectScannerDetector, "cTargetPos", targetPos.x, targetPos.y, targetPos.z )
			EntityService:SetGraphicsUniform( self.effectScannerDetector, "cCenterPos", itemPos.x, itemPos.y, itemPos.z )
			EntityService:SetGraphicsUniform( self.effectScannerDetector, "cRadius", radius )
			local playerId = PlayerService:GetPlayerForEntity(self.owner )
			if type == "enemy" then
				PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_geoscanner_trap.wav", true, 5 )
				EntityService:SetGraphicsUniform( self.effectScannerDetector, "cIsEnemy", 1 )
			else
				PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_geoscanner_treasure.wav", true, 5 )
				EntityService:SetGraphicsUniform( self.effectScannerDetector, "cIsEnemy", 0 )
			end

			if ( mode > 2 ) then
				factor = Clamp(factor, 0.0, 0.999)
				self:SetSynthParam( self.effectDetector, "latency", 1.0 / ( 1.0 - factor ) / 25.0 )
			else
				self:SetSynthParam( self.effectDetector, "latency", 1.0 )
			end
			if ( type ~= "enemy") then
				return
			end
		end
		
		if ( type == "enemy") then
			for eEnt in Iter(enemyEntities ) do
				local eDistance = EntityService:GetDistanceBetween(eEnt, self.item)
				local db = EntityService:GetDatabase( eEnt )
				local discoverDistance = defaultDiscoverDistance
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
	
	elseif ( self.effectDetector ~= nil and self.effectDetector ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.effectDetector )
		self.effectDetector  = INVALID_ID

		EntityService:SetGraphicsUniform( self.effectScannerDetector, "cAlpha", 0 )

		self.type = ""
		self.lastFactor = -1;
	end
end

-- Detector Part End

function scanner:DissolveShow()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

return scanner
