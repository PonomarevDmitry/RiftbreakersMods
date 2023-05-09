require("lua/utils/numeric_utils.lua")

class 'camera_follow_two_targets_by_distance' ( LuaGraphNode )

function camera_follow_two_targets_by_distance:__init()
    LuaGraphNode.__init(self, self)
end

function camera_follow_two_targets_by_distance:init()

end

function camera_follow_two_targets_by_distance:Activated()
		   	
	self.camera = CameraService:GetLeadingPlayerCamera()
	self.player = PlayerService:GetPlayerControlledEnt( 0 ) 
	self.speed = self.data:GetFloat("speed")
	self.acceleration = self.data:GetFloatOrDefault( "acceleration", 0.0 )
	self.maxRadiusDistance = self.data:GetFloatOrDefault( "max_radius_distance", 0.0 )

    local minDistanceTargetName = self.data:GetString("min_distance_target")
    local maxDistanceTargetName = self.data:GetString("max_distance_target")
    local minDistanceTargetEnt = FindService:FindEntityByName( minDistanceTargetName )
    local maxDistanceTargetEnt = FindService:FindEntityByName( maxDistanceTargetName )
    self.minDistanceTargetPos = EntityService:GetPosition( minDistanceTargetEnt )
    self.maxDistanceTargetPos = EntityService:GetPosition( maxDistanceTargetEnt )

    local minCameraTargetName = self.data:GetString("min_camera_target")
    local maxCameraTargetName = self.data:GetString("max_camera_target")
    local minCameraTargetEnt = FindService:FindEntityByName( minCameraTargetName )
    local maxCameraTargetEnt = FindService:FindEntityByName( maxCameraTargetName )
    self.minCameraTargetPos = EntityService:GetPosition( minCameraTargetEnt )
    self.maxCameraTargetPos = EntityService:GetPosition( maxCameraTargetEnt )

	self.oldTargetPos = CameraService:GetLookAtPosition( self.camera )
	self.currentTarget = EntityService:SpawnEntity( self.oldTargetPos )
	self.destinationTarget = EntityService:SpawnEntity( self.oldTargetPos )

	CameraService:SetFollowTarget( self.camera, self.currentTarget )
	MoveService:FollowTarget( self.currentTarget, self.destinationTarget, self.speed, self.acceleration )
end

function camera_follow_two_targets_by_distance:Update()
	if EntityService:IsAlive( self.player ) then
	    local playerPos = EntityService:GetPosition( self.player )

	    local h = VectorSub( self.minDistanceTargetPos, self.maxDistanceTargetPos )
		local u1 = DotProduct( VectorSub( playerPos, self.minDistanceTargetPos ), VectorSub( self.maxDistanceTargetPos, self.minDistanceTargetPos ) )
		local u2 = DotProduct( h, h )
	    local u = math.max( u1 / u2, 0.0 )

	    local pointOnLine = VectorAdd( self.minDistanceTargetPos, VectorMulByNumber( h, u ) )

	    local distanceToPoint = Distance( self.minDistanceTargetPos, pointOnLine )
	    local maxDistanceToPoint = Length( h )
	    distanceToPoint = Clamp( distanceToPoint, 0.0, maxDistanceToPoint )
	    local t1 = distanceToPoint / maxDistanceToPoint

		local t2 = 0.0
	    if self.maxRadiusDistance > 0.0 then 
	   		local distanceToMinPoint = Distance( self.minDistanceTargetPos, playerPos )
	   		t2 = Clamp( ( distanceToMinPoint / self.maxRadiusDistance ) - 1.0, 0.0, 1.0 )
	    end

	    local t = Clamp( math.max( t1, t2 ), 0.0, 1.0 )
		local targetPos = VectorLerp( self.minCameraTargetPos, self.maxCameraTargetPos, t )
		EntityService:SetPosition( self.destinationTarget, targetPos )
	end
end

function camera_follow_two_targets_by_distance:Interrupted()
	self:SetFinished()

	EntityService:RemoveEntity( self.currentTarget )
	EntityService:RemoveEntity( self.destinationTarget )
end

return camera_follow_two_targets_by_distance