local item = require("lua/items/item.lua")

class 'teleport' ( item )

function teleport:__init()
	item.__init(self,self)
end

local function ComputeTeleportTimes(distance)
	local norm = distance / 50.0
	if norm < 0.0 then norm = 0.0 end
	if norm > 1.0 then norm = 1.0 end
	local tDisappear = 0.1 + (0.2 - 0.1) * norm
	local tWait = 0.0 + (0.1 - 0.0) * norm
	local tAppear = 0.1 + (0.2 - 0.1) * norm
	return tDisappear, tWait, tAppear
end

function teleport:OnInit()
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
	self.marker = INVALID_ID
	self.foundPos = { false, {} }
	
	self.maxDistance = self.data:GetFloatOrDefault("distance", -1.0 )
	self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
	self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )

	self.teleportMachine = self:CreateStateMachine()
	self.teleportMachine:AddState( "teleport", { enter="OnTeleportEnter", execute="OnTeleportExecute", exit="OnTeleportExit" } )

	self.dangerMarkerBp = self.data:GetStringOrDefault( "danger_marker_bp", "" )
	self.lightningBp = self.data:GetStringOrDefault("lightning_bp", "")
	self.bp = self.data:GetStringOrDefault( "bp", "" )

	self.teleportVersion = 1
end

function teleport:OnMoveEnd( evt )
	if ( self.teleportMachine ~= nil and evt:GetEntity() == self.oldTarget ) then
		self.teleportMachine:Deactivate()
	end
end

function teleport:OnTeleportEnter( state )
	if self.foundPos.first == false then 
		return
	end

	local player = PlayerService:GetPlayerByMech( self.owner )
	local camera = CameraService:GetPlayerCamera( player )
	local database = EntityService:GetDatabase( self.owner )
	local oldTargetPos = EntityService:GetPosition( self.owner )

	self.oldTarget = EntityService:SpawnEntity( oldTargetPos )
	self.newTarget = EntityService:SpawnEntity( self.foundPos.second )

	local diff = VectorSub( self.foundPos.second, oldTargetPos )
	local distance = Length( diff )
	local tDisappear, tWait, tAppear = ComputeTeleportTimes(distance)
	local totalTime = tDisappear + tWait + tAppear

	if totalTime < 0.001 then totalTime = 0.001 end
	if distance < 0.001 then distance = 0.001 end

	local computedSpeed = (2.0 * distance) / totalTime
	local computedAcceleration = (4.0 * distance) / (totalTime * totalTime)

	MoveService:MoveToTarget( self.oldTarget, self.newTarget, computedSpeed, computedAcceleration )

    if database ~= nil then
		if database:GetIntOrDefault( "block_camera_teleport", 0 ) == 0 then
			CameraService:SetFollowTarget( camera , self.oldTarget )
		end
	end

	self:RegisterHandler( self.oldTarget , "MoveEndEvent", "OnMoveEnd")

	self.lightningEnt = INVALID_ID
	if self.lightningBp ~= "" and self.lightningBp ~= nil then
		self.lightningEnt = EntityService:SpawnAndAttachEntity( self.lightningBp, self.oldTarget )
        local lightningDataComponent = EntityService:GetComponent( self.lightningEnt, "LightningDataComponent")
        if lightningDataComponent ~= nil then
            local component = reflection_helper(lightningDataComponent)
            local container = rawget(component.lighning_vec, "__ptr");
            local instance =  reflection_helper(container:CreateItem())

		    instance.start_point.x = oldTargetPos.x
		    instance.start_point.y = oldTargetPos.y + 3
		    instance.start_point.z = oldTargetPos.z

		    instance.end_point.x = self.foundPos.second.x
		    instance.end_point.y = self.foundPos.second.y + 3
		    instance.end_point.z = self.foundPos.second.z
        end
	end 
end

function teleport:OnTeleportExecute( state )
	if self.lightningEnt ~= INVALID_ID then
        local lightningDataComponent = EntityService:GetComponent( self.lightningEnt, "LightningDataComponent")
        if lightningDataComponent ~= nil then
            local component = reflection_helper(lightningDataComponent)
            local container = rawget(component.lighning_vec, "__ptr");
            local instance =  reflection_helper(container:GetItem( 0 ))

            local oldTargetPos = EntityService:GetPosition( self.oldTarget )
            local newTargetPos = EntityService:GetPosition( self.newTarget )

		    instance.start_point.x = oldTargetPos.x
		    instance.start_point.y = oldTargetPos.y + 3
		    instance.start_point.z = oldTargetPos.z

		    instance.end_point.x = newTargetPos.x
		    instance.end_point.y = newTargetPos.y + 3
		    instance.end_point.z = newTargetPos.z
        end
	end 
end

function teleport:OnTeleportExit( state )
	self:UnregisterHandler( self.oldTarget, "MoveEndEvent", "OnMoveEnd" )
	EntityService:RemoveEntity( self.oldTarget )
	EntityService:RemoveEntity( self.newTarget )

	self.newTarget = INVALID_ID
	self.oldTarget = INVALID_ID
	self.lightningEnt = INVALID_ID

	local player = PlayerService:GetPlayerByMech( self.owner )
	local camera = CameraService:GetPlayerCamera( player )
	local database = EntityService:GetDatabase( self.owner )

	if database ~= nil then
		if database:GetIntOrDefault( "block_camera_teleport", 0 ) == 0 then
			CameraService:SetFollowTarget( camera, self.owner )
		end
	end

	if self.bp ~= "" then 
		local pos = EntityService:GetPosition( self.owner )
		local entity = EntityService:SpawnEntity( self.bp, pos, EntityService:GetTeam( self.owner ))
		ItemService:SetItemCreator( entity, self.entity_blueprint );
		EntityService:PropagateEntityOwner( entity, self.owner )
	end
end

function teleport:OnTeleportAppearEnter()
	self.data:SetInt("leaving", 1)
end

function teleport:OnTeleportAppearExit()
	self.data:SetInt("leaving", 0)
end

function teleport:OnEquipped()
	self.machine:ChangeState("marker")
end

function teleport:OnActivate()
	if ( self.foundPos.first ) then
		local player = PlayerService:GetPlayerByMech( self.owner )
		local camera = CameraService:GetPlayerCamera( player )
		local oldTargetPos = EntityService:GetPosition( self.owner )
		local diff = VectorSub( self.foundPos.second, oldTargetPos )
		local distance = Length( diff )
		local tDisappear, tWait, tAppear = ComputeTeleportTimes(distance)
		PlayerService:TeleportPlayer( self.owner, self.foundPos.second , tDisappear, tWait, tAppear )

		if self.dangerMarkerBp ~= "" and self.dangerMarkerBp ~= nil then
			WeaponService:SpawnDangerMarker( self.dangerMarkerBp, self.foundPos.second, 3.0, 0.3 )
		end

		self.teleportMachine:ChangeState("teleport")
	else
		ItemService:ResetCooldown( self.entity, 0.0 )
	end
end

function teleport:OnMarkerExecute( state )
	local pos = PlayerService:GetWeaponLookPoint( self.owner )
	self.foundPos = PlayerService:FindPositionForTeleport( self.owner, pos, self.maxDistance )
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

function teleport:OnMarkerExit()
	if ( ItemService:IsItemReference( self.marker, self.entity ) ) then
		EntityService:RemoveEntity( self.marker )
	end
	self.marker = INVALID_ID
end

function teleport:OnUnequipped()
	local state  = self.machine:GetState(self.machine:GetCurrentState())
	if( state ~= nil ) then
		state:Exit()
	end
end

function teleport:OnLoad()
	item.OnLoad(self)
	self.version = self.version or 0
	if ( self.version < 1 and self.marker ~= INVALID_ID ) then
		if ( EntityService:GetBlueprintName( self.marker ) ~= "effects/mech/teleport_marker") then
			self.marker = INVALID_ID
		end
	end

	if ( self.teleportVersion == nil ) then
		self.teleportMachine = self:CreateStateMachine()
		self.teleportMachine:AddState( "teleport", { enter="OnTeleportEnter", execute="OnTeleportExecute", exit="OnTeleportExit" } )

		self.dangerMarkerBp = self.data:GetStringOrDefault( "danger_marker_bp", "")
		self.bp = self.data:GetStringOrDefault( "bp", "" )
		self.teleportVersion = 1
	end

	if ( not self:ValidateEntityReference( self.marker ) ) then
		self.marker = INVALID_ID
	end
end

return teleport
