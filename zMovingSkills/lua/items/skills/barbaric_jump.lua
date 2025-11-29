local item = require("lua/items/item.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/reflection.lua")

class 'barbaric_jump' ( item )

function barbaric_jump:__init()
	item.__init(self,self)
end

function barbaric_jump:OnInit()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "jump", { enter="OnJumpEnter", execute="OnJumpExecute", exit="OnJumpExit" } )

	self.markerMachine = self:CreateStateMachine()
	self.markerMachine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
	self.marker = INVALID_ID

	self:InitalizeValues()
end

function barbaric_jump:InitalizeValues()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
	self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.jumpDistance     = database:GetFloatOrDefault( "jump_distance", -1) -- Jump distance -1 == infinite
	self.jumpSpeed 		  = database:GetFloatOrDefault("jump_speed", 2 )     -- animation multiplier for jump start and jump end
	self.maxHeight 		  = database:GetFloatOrDefault( "max_height", 15)    -- max jump height 
	self.peakStart 		  = database:GetFloatOrDefault( "peak_start", 0.5)  -- top slowdown start on reaching this point of jump (0-1)
	self.peakEnd   		  = database:GetFloatOrDefault( "peak_end", 0.7)   -- top slowdown ends on reaching this point of jump (0-1 )
	self.slowdownFactor   = database:GetFloatOrDefault( "slowdown_factor", 4)-- slowdown multiplier betwean peak points
 	self.minTime   		  = database:GetFloatOrDefault( "min_time", 0.375)    -- min jump time + slowdown
	self.maxTime   		  = database:GetFloatOrDefault( "max_time", 0.75)     -- max jump time + slowdown
	self.triggerBp = database:GetString( "trigger" )
	self.radiusBp = database:GetStringOrDefault( "radius_bp", "")
	self.dashStartLong 	  = database:GetStringOrDefault( "dash_start", "effects/items/power_jump_start")
	self.dashTrailLong 	  = database:GetStringOrDefault( "dash_trail", "effects/projectiles_and_trails/mech_dash_trail_short")
	self.dangerMarkerBp   = database:GetStringOrDefault( "danger_marker_bp", "")
	self.autoamingLeft = nil
	self.autoamingRight = nil
	self.enabled = 0
	self.trigger = INVALID_ID
end

function barbaric_jump:OnEquipped()
	local data = EntityService:GetDatabase(self.owner );
	if ( data ~= nil )  then
		data:SetInt("is_jumping", 0 )
	end

	self.markerMachine:ChangeState("marker")
end

function barbaric_jump:OnActivate()
	if ( self.enabled == 0 ) then
		self.machine:ChangeState("jump")
		EffectService:SpawnEffect( self.owner, self.dashStartLong, "att_ribbon_horizontal" )
		EffectService:AttachEffect( self.owner, self.dashTrailLong, "att_ribbon_vertical" )
		EffectService:AttachEffect( self.owner, self.dashTrailLong, "att_ribbon_horizontal" )
	end
end

function barbaric_jump:OnUnequipped()
	if( self.enabled ~= 0 ) then
		self:OnJumpExit( self.machine:GetCurrentState())
		self.machine:Deactivate()
		EffectService:DestroyEffect( self.owner, self.dashTrailLong, "att_ribbon_vertical" )
		EffectService:DestroyEffect( self.owner, self.dashTrailLong, "att_ribbon_horizontal" )
	end

	local state  = self.markerMachine:GetState(self.markerMachine:GetCurrentState())
	if( state ~= nil ) then
		state:Exit()
	end
end

function barbaric_jump:OnMarkerExecute( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	self.foundPos = PlayerService:FindPositionForJump( self.owner, pos ,self.jumpDistance, self.maxHeight)
	if ( self.foundPos.first == false and self.marker ~= INVALID_ID ) then
		if ( ItemService:IsItemReference( self.marker, self.entity ) ) then
			EntityService:RemoveEntity( self.marker )
		end
		self.marker = INVALID_ID 
	elseif ( self.foundPos.first and ( self.marker == INVALID_ID or EntityService:IsAlive( self.marker ) == false ) ) then
		self.marker = EntityService:SpawnEntity("effects/mech/teleport_marker", self.foundPos.second, EntityService:GetTeam(INVALID_ID) )
		ItemService:SetItemReference( self.marker, self.entity, EntityService:GetBlueprintName( self.entity ) )
	elseif ( self.foundPos.first and self.marker ~= INVALID_ID ) then
		EntityService:SetPosition( self.marker, self.foundPos.second )
		EntityService:CreateOrSetLifetime( self.marker, 2.0 / 33.0, "normal" )
		EntityService:SetVisible( self.marker, PlayerService:IsInFighterMode( self.owner ) )
	end
end

function barbaric_jump:OnMarkerExit()
	if ( ItemService:IsItemReference( self.marker, self.entity ) ) then
		EntityService:RemoveEntity( self.marker )
	end
	self.marker = INVALID_ID
end

function barbaric_jump:OnJumpEnter( state )
	
	EntityService:DisableCollisions( self.owner )
	EntityService:DisableCharacterController( self.owner )

	self.jumpPoint = PlayerService:GetWeaponLookPoint( self.owner )
	local foundPos = PlayerService:FindPositionForTeleport( self.owner, self.jumpPoint, self.jumpDistance )

	local data = EntityService:GetDatabase(self.owner );
	if ( data == nil ) then
		state:Exit()
		self.enabled = 0
		return
	end
	if ( data:HasInt( "is_LEFT_HAND_autoaiming" ) ) then
		self.autoamingLeft = data:GetInt( "is_LEFT_HAND_autoaiming" )
	end

	if ( data:HasInt( "is_RIGHT_HAND_autoaiming" ) ) then
		self.autoamingRight = data:GetInt( "is_RIGHT_HAND_autoaiming" )
	end

	if ( foundPos.first == false ) then
		ItemService:ResetCooldown( self.entity, 0.0)
		state:Exit();
		return
	end

	self.jumpPoint = foundPos.second
	self.startPosition = EntityService:GetPosition( self.owner )

	local distance = Distance( self.startPosition, self.jumpPoint )

	data:SetFloat( "jump_speed", self.jumpSpeed )
	
	local time = 1
	if ( self.jumpDistance ~= -1 ) then
		time = Lerp( self.minTime, self.maxTime, distance / self.jumpDistance)
	end

	self.enabled = 2;
	data:SetInt("is_jumping", 1 )
	data:SetInt("is_LEFT_HAND_autoaiming", 0 )
	data:SetInt("is_RIGHT_HAND_autoaiming", 0 )

	EntityService:ChangeGravityAffected( self.owner, false )
	PlayerService:StartJump( self.owner, self.jumpPoint, self.maxHeight, time, self.peakStart, self.peakEnd, self.slowdownFactor )
	self.trigger = EntityService:SpawnAndAttachEntity( self.triggerBp, self.owner, "att_forward_trigger", "" )
	self.lastHeight = self.startPosition.y
	QueueEvent( "HideComponentRequest", self.owner, "TerrainAffectedComponent" )
	self.timer =  0

	WeaponService:SpawnDangerMarker( self.dangerMarkerBp, self.jumpPoint, 3.0, 0.5 )

	local component = EntityService:GetComponent( self.owner, "MechPredictionComponent")
    if component ~= nil then
		local mechPredictionComponent = reflection_helper( component )
	    if mechPredictionComponent ~= nil then
	    	mechPredictionComponent.block_prediction = true
	    end
	end
end

function barbaric_jump:OnJumpExecute( state, dt )
	local data = EntityService:GetDatabase(self.owner );
	if ( data and data:HasInt("is_jumping") and data:GetInt( "is_jumping" ) == 0 and self.enabled == 2 ) then
		state:SetDurationLimit( 0.6 )
	end

	if( self.enabled == 2 and  EntityService:GetComponent( self.owner ,"SimpleMovementComponent") == nil ) then

		EntityService:EnableCollisions( self.owner )
		EntityService:EnableCharacterController( self.owner )

		local entity = EntityService:SpawnEntity( self.bp, self.jumpPoint, EntityService:GetTeam( self.owner ))
		ItemService:SetItemCreator( entity, self.entity_blueprint );
		EntityService:PropagateEntityOwner( entity, self.owner )

		if ( self.radiusBp ~= "" ) then
			local points = FindService:GetSpotsInRadius( self.owner, 0, self.data:GetFloat("radius_size") )
			for pos in Iter(points) do
				local trail = EntityService:SpawnEntity( self.radiusBp, pos, EntityService:GetTeam( self.owner ))
				ItemService:SetItemCreator( trail, self.entity_blueprint );
				EntityService:PropagateEntityOwner( trail, self.owner )
				EntityService:DissolveEntity( trail, self.data:GetFloat("radius_lifetime"), 1.0 )	
			end
		end
		self.enabled = 1
		self:FinalizePostJump()
	end
end

function barbaric_jump:FinalizePostJump()
	EffectService:DestroyEffect( self.owner, self.dashTrailLong, "att_ribbon_vertical" )
	EffectService:DestroyEffect( self.owner, self.dashTrailLong, "att_ribbon_horizontal" )
	EntityService:ChangeGravityAffected( self.owner, true )

	if ( self.trigger ~= INVALID_ID ) then
		EntityService:RemoveEntity( self.trigger )
		self.trigger = INVALID_ID
	end

	local data = EntityService:GetDatabase(self.owner );
	if ( data ) then
		data:SetInt("is_jumping", 0 )

		if ( self.autoamingLeft ~= nil ) then
			data:SetInt("is_LEFT_HAND_autoaiming", self.autoamingLeft )
			self.autoamingLeft = nil
		else
			data:RemoveKey("is_LEFT_HAND_autoaiming")
		end
		if ( self.autoamingRight ~= nil ) then
			data:SetInt("is_RIGHT_HAND_autoaiming", self.autoamingRight )
			self.autoamingRight = nil
		else
			data:RemoveKey("is_RIGHT_HAND_autoaiming")
		end
	end

	self.enabled = 0
	QueueEvent( "RevealComponentRequest", self.owner, "TerrainAffectedComponent" )

    local mechPredictionComponent = reflection_helper( EntityService:GetComponent( self.owner, "MechPredictionComponent"))
    if mechPredictionComponent ~= nil then
    	mechPredictionComponent.block_prediction = false
    end
end

function barbaric_jump:OnJumpExit( state )
	EntityService:EnableCollisions( self.owner )
	EntityService:EnableCharacterController( self.owner )
	self:FinalizePostJump()
end

function barbaric_jump:OnLoad()
	item.OnLoad( self )
	self:InitalizeValues()

	if self.markerMachine == nil then
		self.markerMachine = self:CreateStateMachine()
		self.markerMachine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
		self.marker = INVALID_ID
	end
end

return barbaric_jump
