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
	self:InitalizeValues()
end

function barbaric_jump:InitalizeValues()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
	self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.jumpDistance     = database:GetFloatOrDefault( "jump_distance", -1) -- Jump distance -1 == infinite
	self.jumpSpeed 		  = database:GetFloatOrDefault("jump_speed", 1 )     -- animation multiplier for jump start and jump end
	self.maxHeight 		  = database:GetFloatOrDefault( "max_height", 15)    -- max jump height 
	self.peakStart 		  = database:GetFloatOrDefault( "peak_start", 0.85)  -- top slowdown start on reaching this point of jump (0-1)
	self.peakEnd   		  = database:GetFloatOrDefault( "peak_end", 0.94 )   -- top slowdown ends on reaching this point of jump (0-1 )
	self.slowdownFactor   = database:GetFloatOrDefault( "slowdown_factor", 4)-- slowdown multiplier betwean peak points
 	self.minTime   		  = database:GetFloatOrDefault( "min_time", 0.75)    -- min jump time + slowdown
	self.maxTime   		  = database:GetFloatOrDefault( "max_time", 1.5)     -- max jump time + slowdown
	self.triggerBp = database:GetString( "trigger" )
	self.radiusBp = database:GetStringOrDefault( "radius_bp", "")
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
end

function barbaric_jump:OnActivate()
	if ( self.enabled == 0 ) then
		self.machine:ChangeState("jump")
		QueueEvent("SpawnEffectGroupRequest", self.owner, "dash_start_long", 0 )
		QueueEvent("AttachEffectGroupRequest", self.owner, "dash_trail_long", 0 )
	end
end

function barbaric_jump:OnUnequipped()
	if( self.enabled ~= 0 ) then
		self:OnJumpExit( self.machine:GetCurrentState())
		self.machine:Deactivate()
		QueueEvent("RemoveEffectsByGroupRequest", self.owner, "dash_trail_long", 0 )
	end
end

function barbaric_jump:OnJumpEnter( state )
	self.jumpPoint = PlayerService:GetWeaponLookPoint( self.owner )
	
	--local foundPos = PlayerService:FindPositionForJump( self.owner, self.jumpPoint ,self.jumpDistance, self.maxHeight)

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

	local mechComponent = EntityService:GetComponent(self.owner, "MechComponent")
	if (mechComponent) then
		local helper = reflection_helper(mechComponent)
		helper.melee_attack_lock_aiming = 1
		helper.lock_moving = 1
	end

	EntityService:ChangeGravityAffected( self.owner, false )
	PlayerService:StartJump( self.owner, self.jumpPoint, self.maxHeight, time, self.peakStart, self.peakEnd, self.slowdownFactor )
	self.trigger = EntityService:SpawnAndAttachEntity( self.triggerBp, self.owner, "att_forward_trigger", "" )
	self.lastHeight = self.startPosition.y
	QueueEvent( "HideComponentRequest", self.owner, "TerrainAffectedComponent" )
	self.timer =  0
end

function barbaric_jump:OnJumpExecute( state, dt )
	local data = EntityService:GetDatabase(self.owner );
	if ( data and data:HasInt("is_jumping") and data:GetInt( "is_jumping" ) == 0 and self.enabled == 2 ) then
		state:SetDurationLimit( 0.6 )
	end

	if( self.enabled == 2 and  EntityService:GetComponent( self.owner ,"SimpleMovementComponent") == nil ) then
		local entity = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
		ItemService:SetItemCreator( entity, self.entity_blueprint );

		if ( self.radiusBp ~= "" ) then
			local points = FindService:GetSpotsInRadius( self.owner, 0, self.data:GetFloat("radius_size") )
			for pos in Iter(points) do
				local trail = EntityService:SpawnEntity( self.radiusBp, pos, EntityService:GetTeam( self.owner ))
				ItemService:SetItemCreator( trail, self.entity_blueprint );
				EntityService:DissolveEntity( trail, self.data:GetFloat("radius_lifetime"), 1.0 )	
			end
		end
		self.enabled = 1
	end


end

function barbaric_jump:OnJumpExit( state )

	local mechComponent = EntityService:GetComponent(self.owner, "MechComponent")
	if (mechComponent) then
		local helper = reflection_helper(mechComponent)
		helper.melee_attack_lock_aiming = 0
		helper.lock_moving = 0
	end
	
	QueueEvent("RemoveEffectsByGroupRequest", self.owner, "dash_trail_long", 0 )
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
end

function barbaric_jump:OnLoad()
	item.OnLoad( self )
	self:InitalizeValues()
end

return barbaric_jump
