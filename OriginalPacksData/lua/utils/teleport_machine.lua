class 'teleport_machine' ( LuaEntityObject )
require("lua/utils/table_utils.lua")

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
    self.hiddenChildren = {}
    self.fsm:ChangeState("disappear")
end

function teleport_machine:OnLoad()
    self.hiddenChildren = self.hiddenChildren or {}
end

function teleport_machine:OnDisappearEnter( state)
    EntityService:FadeEntity( self.parent, DD_FADE_OUT, self.disappearTime, false )
    QueueEvent("RiftTeleportStartEvent", self.parent )
    QueueEvent("AttachEffectGroupRequest", self.parent, "portal_enter", 0 )

    self.hiddenChildren = {}
    local children = EntityService:GetChildren( self.parent, true )
	for child in Iter(children) do
		if ( EntityService:IsVisible( child ) ) then		
            EntityService:FadeEntity( child, DD_FADE_OUT, self.disappearTime, false )
            Insert(self.hiddenChildren, child )
        end
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
    EntityService:FadeEntity( self.parent, DD_FADE_IN, self.appearTime, false )
    QueueEvent("AttachEffectGroupRequest", self.parent, "portal_exit", 0 )
    QueueEvent("TeleportAppearEnter", self.portalEntity )

	for child in Iter(self.hiddenChildren) do
        EntityService:FadeEntity( child, DD_FADE_IN, 0.5 , false)
    end
    self.hiddenChildren = {}
    state:SetDurationLimit( self.appearTime )
end

function teleport_machine:OnAppearExit( state)
    QueueEvent("RiftTeleportEndEvent", self.parent )
    QueueEvent("TeleportAppearExit", self.portalEntity )
    local portalComponent = EntityService:GetComponent( self.portalEntity, "RiftPointComponent")
    if ( portalComponent ~= nil ) then
        local helper = reflection_helper(portalComponent)
        if ( helper.name == "temp_rift") then
            QueueEvent("DissolveEntityRequest", self.portalEntity, 0.5, 0.0)
        end
    end


    HealthService:SetImmortality( self.parent, false )

    local playerId = PlayerService:GetPlayerByMech( self.parent )

    if ( playerId ~= INVALID_ID ) then 
        CampaignService:UpdateAchievementProgress( ACHIEVEMENT_BEAM_ME_UP, 1, playerId )
    end
    
    EntityService:RemoveEntity( self.entity )
end

return teleport_machine