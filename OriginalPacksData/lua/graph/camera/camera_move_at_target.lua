class 'camera_move_at_target' ( LuaGraphNode )

function camera_move_at_target:__init()
    LuaGraphNode.__init(self, self)
end

function camera_move_at_target:init()
end

function camera_move_at_target:Activated()		
	local targetName = self.data:GetString("target_name")	
	local targetGroup = self.data:GetString("target_group")	
	local targetType = self.data:GetString("target_type")	
	local targetBlueprint = self.data:GetString("target_blueprint")

	local speed = self.data:GetFloat( "speed" )
	local acceleration = self.data:GetFloatOrDefault( "acceleration", 0.0 )
	self.back_to_player = self.data:GetInt("lock_camera") == 1

	self.target = nil
	
	if targetName ~= "" then
		self.target = FindService:FindEntityByName( targetName )
	elseif targetGroup ~= "" then
		self.target = FindService:FindEntityByGroup( targetGroup )
	elseif targetType ~= "" then
		self.target = FindService:FindEntityByType( targetType )
	elseif targetBlueprint ~= "" then
		self.target = FindService:FindEntityByBlueprint( targetBlueprint )
	end
		
	self.playerDataVec = {}
 	local players = PlayerService:GetConnectedPlayers()
	for player in Iter( players ) do

		local camera = CameraService:GetPlayerCamera( player )
		local oldTargetPos = CameraService:GetLookAtPosition( camera )
		local currentTarget = EntityService:SpawnEntity( oldTargetPos )

		MoveService:MoveToTarget( currentTarget, self.target, speed, acceleration )
		CameraService:SetFollowTarget( camera , currentTarget )

		self:RegisterHandler( currentTarget , "MoveEndEvent", "OnMoveEnd")
		table.insert( self.playerDataVec, { player, currentTarget } )
	end
end

function camera_move_at_target:OnMoveEnd( event )
	local playerDataIdx = nil
	for i = 1, #self.playerDataVec do			
		if self.playerDataVec[i][2] == event:GetEntity() then
			playerDataIdx = i
			break
		end			
	end

	if playerDataIdx ~= nil then
		local playerData = self.playerDataVec[playerDataIdx]
		self:UnregisterHandler( playerData[2], "MoveEndEvent", "OnMoveEnd" )
		EntityService:RemoveEntity( playerData[2] )

		if ( self.back_to_player == true ) then
			local camera = CameraService:GetPlayerCamera( playerData[1] )
			CameraService:SetFollowTarget( camera , self.target )
		end

		table.remove( self.playerDataVec, playerDataIdx )
	end

	if #self.playerDataVec == 0 then
		self:SetFinished()
	end
end

return camera_move_at_target