class 'entity_spawn_player' ( LuaGraphNode )

function entity_spawn_player:__init()
    LuaGraphNode.__init(self, self)
end

function entity_spawn_player:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { execute="OnExecuteWait", interval=0.5 } )
end

function entity_spawn_player:OnLoad()
	if not self.fsm then
		self.fsm = self:CreateStateMachine()
	end

	if not self.fsm:GetState("wait" ) then
		self.fsm:AddState( "wait", { execute="OnExecuteWait", interval=0.5 } )
	end

	if self.parent:IsNodeActive( self.self_id ) then
		if self.fsm:GetCurrentState() ~= "wait" then
			self.fsm:ChangeState("wait")
		end
	end
end

function entity_spawn_player:Activated()
	self.fsm:ChangeState("wait")
end

function entity_spawn_player:OnExecuteWait( state )
	local mechs = PlayerService:GetPlayersMechs( )
	if ( #mechs > 0) then
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