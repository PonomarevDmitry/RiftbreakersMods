class 'teleport_machine' ( LuaEntityObject )

function teleport_machine:__init()
	LuaEntityObject.__init(self, self)
end

function teleport_machine:init()

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "disappear", { enter="OnDisappearEnter", exit="OnDisappearExit" } )
	self.fsm:AddState( "wait", {enter="OnWaitEnter", execute="OnWaitExecute", exit="OnWaitExit" } )
	self.fsm:AddState( "appear", {enter="OnAppearEnter", exit="OnAppearExit"  } )

    if ( self.data:HasInt( "target")) then
        local target  = self.data:GetInt( "target" )
        if ( EntityService:IsAlive( target ) ) then
            self.destination = EntityService:GetWorldPosition( target )
        else
            EntityService:RemoveEntity(self.entity )
            return  
        end
    elseif( self.data:HasVector("target") ) then
        self.destination = self.data:GetVector("target")
    else
        EntityService:RemoveEntity(self.entity )
        return  
    end


    self.disappearTime = self.data:GetFloatOrDefault( "disappear_time", 0.0 )
    self.waitTime = self.data:GetFloatOrDefault( "wait_time", 0.0 )
    self.appearTime = self.data:GetFloatOrDefault( "appear_time", 0.0 )
    self.portalEntity = self.data:GetIntOrDefault( "portal_entity", -1 )
    if ( self.portalEntity < 0 ) then
        self.portalEntity = INVALID_ID
    end
    self.parent = EntityService:GetParent( self.entity )

    self.teleported = false

    self.fsm:ChangeState("disappear")
end

function teleport_machine:OnDisappearEnter( state)
    QueueEvent("FadeEntityOutRequest", self.parent, self.disappearTime )
    QueueEvent("RiftTeleportStartEvent", self.parent )
    QueueEvent("AttachEffectGroupRequest", self.parent, "portal_enter", 0 )

    local children = EntityService:GetChildren( self.parent, true )
	for child in Iter(children) do
        EntityService:SetVisible( child, false )
    end
    HealthService:SetImmortality( self.parent, true )

    state:SetDurationLimit( self.disappearTime )
end

function teleport_machine:OnDisappearExit( state)
    self.fsm:ChangeState("wait")
end

function teleport_machine:OnWaitEnter( state)
    state:SetDurationLimit( self.waitTime )
end

function teleport_machine:OnWaitExecute( state)
    if ( not self.teleported and  (state:GetDuration() >= self.waitTime / 2.0) ) then
        EntityService:Teleport( self.parent, self.destination )
        self.teleported = true
    end
end

function teleport_machine:OnWaitExit( state)
    self.fsm:ChangeState("appear")
    if ( not self.teleported ) then
        EntityService:Teleport( self.parent, self.destination )
    end
end

function teleport_machine:OnAppearEnter( state)
    QueueEvent("FadeEntityInRequest", self.parent, self.appearTime )
    QueueEvent("AttachEffectGroupRequest", self.parent, "portal_exit", 0 )
    QueueEvent("TeleportAppearEnter", self.portalEntity )

    state:SetDurationLimit( self.appearTime )
end

function teleport_machine:OnAppearExit( state)
    QueueEvent("RiftTeleportEndEvent", self.parent )
    QueueEvent("TeleportAppearExit", self.portalEntity )


    local children = EntityService:GetChildren( self.parent, true )
	for child in Iter(children) do
        EntityService:SetVisible( child, true )
    end

    HealthService:SetImmortality( self.parent, false )

    if ( PlayerService:GetPlayerByMech( self.parent ) ~= INVALID_ID ) then
        CampaignService:UpdateAchievementProgress(ACHIEVEMENT_BEAM_ME_UP, 1)
    end
    
    EntityService:RemoveEntity(self.entity )
end

return teleport_machine