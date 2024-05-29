local player_modificator_source = require("lua/misc/player_modificator_source.lua")

class 'power_well' ( player_modificator_source )

function power_well:__init()
	player_modificator_source.__init(self,self)
end

function power_well:UpdateWorkingState()
    local working = 0
    if not self.activated and self.entities_in_trigger > 0 then
        working = 1
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

    self.entities_in_trigger = 0
    self:UpdateWorkingState();
end

function power_well:OnAnimationMarkerReached(evt)
	EffectService:SpawnEffects(self.entity, evt:GetMarkerName())
end

function power_well:OnInteractWithEntityRequest( evt )
    if self.activated then
        return
    end

    CampaignService:UpdateAchievementProgress(ACHIEVEMENT_OPEN_POWER_WELLS, 1)

    self:AttachModificator(evt:GetOwner())

    self.activated = true;
    self:UpdateWorkingState();

    EntityService:RemoveEntity( self.entity, 2.0 )
end

function power_well:OnEnteredTriggerEvent(evt)
    self.entities_in_trigger = ( self.entities_in_trigger or 0 ) + 1

    self:UpdateWorkingState();
end

function power_well:OnLeftTriggerEvent(evt)
    self.entities_in_trigger = ( self.entities_in_trigger or 0 ) - 1

    self:UpdateWorkingState();
end

return power_well