class 'entity_spawn_player' ( LuaGraphNode )

function entity_spawn_player:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_player:init()
end

function entity_spawn_player:Activated()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", execute="OnExecuteWait" } )
	self.fsm:ChangeState("wait")
end

function entity_spawn_player:OnExecuteWait( state )
	local playerId = self.parent:GetDatabase():GetIntOrDefault("player_id", 0 )
	local pawn = PlayerService:GetPlayerControlledEnt(playerId )

	if ( EntityService:IsAlive( pawn )) then
        state:Exit()
		self:SetFinished()
	end
end

-- Legacy stuff
function entity_spawn_player:OnPlayerControlledEntityChangeEvent()
end
function entity_spawn_player:OnPortalOpenExit()
end



return entity_spawn_player