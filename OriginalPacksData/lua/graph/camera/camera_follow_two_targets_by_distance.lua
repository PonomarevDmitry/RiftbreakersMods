require("lua/utils/numeric_utils.lua")

class 'camera_follow_two_targets_by_distance' ( LuaGraphNode )

function camera_follow_two_targets_by_distance:__init()
    LuaGraphNode.__init(self, self)
end

function camera_follow_two_targets_by_distance:init()
	self.speed = self.data:GetFloat("speed")
	self.acceleration = self.data:GetFloatOrDefault( "acceleration", 0.0 )
	self.maxRadiusDistance = self.data:GetFloatOrDefault( "max_radius_distance", 0.0 )
	self.playerDataVec = {}

	self:RegisterHandler( event_sink, "PlayerControlledEntityChangeEvent",  "OnPlayerControlledEntityChangeEvent" )
	self:RegisterHandler( event_sink, "PlayerReactivatedEvent",  "OnPlayerReactivatedEvent" )
end

function camera_follow_two_targets_by_distance:InitPlayer( player )
	local camera = CameraService:GetPlayerCamera( player )

    local minDistanceTargetName = self.data:GetString("min_distance_target")
    local maxDistanceTargetName = self.data:GetString("max_distance_target")
    local minDistanceTargetEnt = FindService:FindEntityByName( minDistanceTargetName )
    local maxDistanceTargetEnt = FindService:FindEntityByName( maxDistanceTargetName )
    local minDistanceTargetPos = EntityService:GetPosition( minDistanceTargetEnt )
    local maxDistanceTargetPos = EntityService:GetPosition( maxDistanceTargetEnt )

    local minCameraTargetName = self.data:GetString("min_camera_target")
    local maxCameraTargetName = self.data:GetString("max_camera_target")
    local minCameraTargetEnt = FindService:FindEntityByName( minCameraTargetName )
    local maxCameraTargetEnt = FindService:FindEntityByName( maxCameraTargetName )
    local minCameraTargetPos = EntityService:GetPosition( minCameraTargetEnt )
    local maxCameraTargetPos = EntityService:GetPosition( maxCameraTargetEnt )

	local oldTargetPos = CameraService:GetLookAtPosition( camera )
	local currentTarget = EntityService:SpawnEntity( oldTargetPos )
	local destinationTarget = EntityService:SpawnEntity( oldTargetPos )

	CameraService:SetFollowTarget( camera, currentTarget )
	MoveService:FollowTarget( currentTarget, destinationTarget, self.speed, self.acceleration )

	local mech = PlayerService:GetPlayerControlledEnt( player )
 	local database = EntityService:GetDatabase( mech )
    if ( database ~= nil) then
		database:SetInt( "block_camera_teleport", 1 )
    end

	for data in Iter( self.playerDataVec ) do
		if ( data[1] == player) then
			data = nil
		end
	end
	table.insert( self.playerDataVec, { player, currentTarget, destinationTarget, minDistanceTargetPos, maxDistanceTargetPos, minCameraTargetPos, maxCameraTargetPos } )
end

function camera_follow_two_targets_by_distance:Activated()
 	local players = PlayerService:GetConnectedPlayers()
	for player in Iter( players ) do
		self:InitPlayer( player )
	end
end

function camera_follow_two_targets_by_distance:OnPlayerControlledEntityChangeEvent( event )
	self:InitPlayer( event:GetPlayerId() )
end

function camera_follow_two_targets_by_distance:OnPlayerReactivatedEvent( event )
	self:InitPlayer( event:GetPlayerId() )
end

function camera_follow_two_targets_by_distance:Update()
	for i = 1, #self.playerDataVec do
		local playerData = self.playerDataVec[i]
		local playerEnt = PlayerService:GetPlayerControlledEnt( playerData[1] )
		if EntityService:IsAlive( playerEnt ) then
		    local playerPos = EntityService:GetPosition( playerEnt )

			local destinationTarget = playerData[3]
		    local minDistanceTargetPos = playerData[4]
		    local maxDistanceTargetPos = playerData[5]
			local minCameraTargetPos = playerData[6]
			local maxCameraTargetPos = playerData[7]

		    local h = VectorSub( minDistanceTargetPos, maxDistanceTargetPos )
			local u1 = DotProduct( VectorSub( playerPos, minDistanceTargetPos ), VectorSub( maxDistanceTargetPos, minDistanceTargetPos ) )
			local u2 = DotProduct( h, h )
		    local u = math.max( u1 / u2, 0.0 )

		    local pointOnLine = VectorAdd( minDistanceTargetPos, VectorMulByNumber( h, u ) )

		    local distanceToPoint = Distance( minDistanceTargetPos, pointOnLine )
		    local maxDistanceToPoint = Length( h )
		    distanceToPoint = Clamp( distanceToPoint, 0.0, maxDistanceToPoint )
		    local t1 = distanceToPoint / maxDistanceToPoint

			local t2 = 0.0
		    if self.maxRadiusDistance > 0.0 then 
		   		local distanceToMinPoint = Distance( minDistanceTargetPos, playerPos )
		   		t2 = Clamp( ( distanceToMinPoint / self.maxRadiusDistance ) - 1.0, 0.0, 1.0 )
		    end

		    local t = Clamp( math.max( t1, t2 ), 0.0, 1.0 )
			local targetPos = VectorLerp( minCameraTargetPos, maxCameraTargetPos, t )
			EntityService:SetPosition( destinationTarget, targetPos )
		end
	end
end

function camera_follow_two_targets_by_distance:Interrupted()
	for i = 1, #self.playerDataVec do	
		EntityService:RemoveEntity( self.playerDataVec[i][2] )
		EntityService:RemoveEntity( self.playerDataVec[i][3] )

		local mech = PlayerService:GetPlayerControlledEnt( self.playerDataVec[i][1] )
	 	local database = EntityService:GetDatabase( mech )
	    if ( database ~= nil) then
			database:SetInt( "block_camera_teleport", 0 )
	    end
	end
	self:SetFinished()
end

return camera_follow_two_targets_by_distance
