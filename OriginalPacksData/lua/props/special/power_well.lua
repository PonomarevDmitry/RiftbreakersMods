local player_modificator_source = require("lua/misc/player_modificator_source.lua")

class 'power_well' ( player_modificator_source )

function power_well:__init()
	player_modificator_source.__init(self,self)
end

function power_well:UpdateWorkingState()
    local working = 0
    if not self.activated then
        for k,v in pairs( self.entities_in_trigger ) do
            working = 1
        end
    end

    self.data:SetInt("working", working)

    local hasEffectsEnabled = EffectService:HasEffectByGroup( self.entity, "container") 
    if working ~= hasEffectsEnabled then
        if working then
            EffectService:AttachEffects( self.entity, "container")
        else
            EffectService:DestroyDelayedEffectsByGroup( self.entity, "container", 1.0 )
        end
    end
end

function power_well:init()
    self:RegisterHandler( self.entity, "InteractWithEntityRequest", "OnInteractWithEntityRequest" )

    self:RegisterHandler( self.entity, "EnteredTriggerEvent", "OnEnteredTriggerEvent" )
    self:RegisterHandler( self.entity, "LeftTriggerEvent", "OnLeftTriggerEvent" )
	self:RegisterHandler( self.entity, "AnimationMarkerReached", "OnAnimationMarkerReached" ) 

    self.entities_in_trigger = {}
    self:UpdateWorkingState();
end

function power_well:OnLoad()
    if type(self.entities_in_trigger) == 'number' then
        self.entities_in_trigger = {}
    end
end

function power_well:OnAnimationMarkerReached(evt)
	EffectService:SpawnEffects(self.entity, evt:GetMarkerName())
end

function power_well:OnInteractWithEntityRequest( evt )
    if self.activated then
        return
    end

    local playerId = PlayerService:GetPlayerByMech( evt:GetOwner() )

    CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_POWER_WELLS, 1, playerId )

    self:AttachModificator(evt:GetOwner())

    self.activated = true;
    self:UpdateWorkingState();

    EntityService:RemoveEntity( self.entity, 2.0 )
end

function power_well:OnEnteredTriggerEvent(evt)
    local tag = evt:Gettag()
    if tag ~= "" and tag ~= "open" then
       return
    end

    self.entities_in_trigger[ evt:GetOtherEntity() ] = true

    self:UpdateWorkingState();
end

function power_well:OnLeftTriggerEvent(evt)
    local tag = evt:Gettag()
    if tag ~= "" and tag ~= "close" then
        return
    end

    self.entities_in_trigger[ evt:GetOtherEntity() ] = nil

    self:UpdateWorkingState();
end

return power_well