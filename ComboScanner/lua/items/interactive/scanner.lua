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
end

function scanner:OnEquipped()
	item.OnEquipped( self ) 
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

function scanner:OnUnequipped()
	item.OnUnequipped( self ) 
end

function scanner:OnActivate( activation_id )
	item.OnActivate( self, activation_id )
	self:OnExecuteScaning()

	QueueEvent("ShowScannableRequest", self.owner, true )

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

	if not ( mod_scanner_not_hide_scannable and mod_scanner_not_hide_scannable == 1 ) then
		QueueEvent("ShowScannableRequest", self.owner, false )
	end
	
	if ( self.effect ~= INVALID_ID )  then
		EntityService:RemoveEntity( self.effect )
		self.effect = INVALID_ID
	end

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
		PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
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

			PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
			EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
		end
		
		if ( currentTarget ~= INVALID_ID ) then		
			local scannableComponent = EntityService:GetComponent( currentTarget, "ScannableComponent")
			if ( scannableComponent == nil ) then
				PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_idle.wav", true, 5 )
				EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_idle")
				return
			end
			local scannableComponentHelper = reflection_helper(scannableComponent)
			if ( self.effect == INVALID_ID ) then
				EntityService:ChangeMaterial( self.ammoEnt, "projectiles/bioscanner_active")
				PlayerService:SetPadHapticFeedback( playerId, "sound/samples/haptic/interactive_bioscanner_scanning.wav", true, 5 )
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

				if ( mod_scanner_instant_scan and mod_scanner_instant_scan == 1 ) then
					maxScanTime = 0
				end

				if ( self.scanningTime >= maxScanTime ) then

					local scansCount = 1
					if ( mod_scanner_size_matters and mod_scanner_size_matters == 1 ) then
						scansCount = ScannerSizeMattersGetScansCount(currentTarget)
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

function scanner:DissolveShow()
	EntityService:FadeEntity( self.item, DD_FADE_OUT, 0.0)
end

return scanner
