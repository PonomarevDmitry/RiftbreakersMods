class 'camera_follow_player' ( LuaGraphNode )

function camera_follow_player:__init()
    LuaGraphNode.__init(self, self)
end

function camera_follow_player:init()
end

function camera_follow_player:Activated()		
	
	local instant = self.data:GetInt("instant") == 1
	local speed = self.data:GetFloat( "speed" )
	local acceleration = self.data:GetFloatOrDefault( "acceleration", 0.0 )

	self.playerDataVec = {}

	local players = {}
    if self.data:HasString("in_players") then
        players = GetEntitiesFromString( self.data:GetString("in_players") )
    else
        players = PlayerService:GetConnectedPlayers()
    end

	for player in Iter( players ) do

		local camera = CameraService:GetPlayerCamera( player )
		local playerEnt = PlayerService:GetPlayerControlledEnt( player )

		if ( instant ) then
			CameraService:SetFollowTarget( camera, playerEnt )
		else
			local oldTargetPos = CameraService:GetLookAtPosition( camera )
			local currentTarget = EntityService:SpawnEntity( oldTargetPos )

			CameraService:SetFollowTarget( camera, currentTarget )
			MoveService:MoveToTarget( currentTarget, playerEnt, speed, acceleration )

			self:RegisterHandler( currentTarget , "MoveEndEvent", "OnMoveEnd")
			table.insert( self.playerDataVec, { player, currentTarget } )
		end
	end

	if ( instant ) then
		self:SetFinished()
	end
end

function camera_follow_player:OnMoveEnd( event )
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

		local camera = CameraService:GetPlayerCamera( playerData[1] )
		local playerEnt = PlayerService:GetPlayerControlledEnt( playerData[1] )
		CameraService:SetFollowTarget( camera, playerEnt )

		table.remove( self.playerDataVec, playerDataIdx )
	end

	if #self.playerDataVec == 0 then
		self:SetFinished()
	end
end

return camera_follow_player