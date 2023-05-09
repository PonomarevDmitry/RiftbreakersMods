local building_base = require("lua/buildings/building_base.lua")
require("lua/utils/reflection.lua")

class 'trap' ( building_base )

function trap:__init()
	building_base.__init(self,self)
end

function trap:OnInit()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent",  "OnLeftTriggerEvent" )
    self:RegisterHandler( self.entity, "TimerElapsedEvent", "OnTimerElapsedEvent")

    self.numberOfActivations = self.data:GetInt("number_of_activations")
    self.damageBlueprint = self.data:GetString("damage_blueprint")
    self.entitiesInsideCount = 0
    self.activated = false
    EntityService:CreateComponent( self.entity, "TimerComponent")
end

function trap:OnTimerElapsedEvent(evt)
    if (evt:GetName() ~= "DamageDealing") then
        return
    end
    self.data:SetFloat("is_activated", 0.0 )
    EffectService:DestroyEffectsByGroup( self.entity, "activated" ) 

    if ( self.numberOfActivations <= 0 ) then
        EntityService:DissolveEntity( self.entity, 1.0 )
    elseif (self.entitiesInsideCount > 0 ) then
        self:ActivateTrap()
    else
        self.activated = false
    end
end

function trap:ActivateTrap()
    EffectService:AttachEffects( self.entity, "activated" ) 
    self.damageEnt = EntityService:SpawnAndAttachEntity(self.damageBlueprint, self.entity, EntityService:GetTeam(self.entity) )
    local areaDamageComponent = reflection_helper( EntityService:GetComponent(self.damageEnt, "AreaDamageComponent"))
    areaDamageComponent.owner_ent = self.entity
    areaDamageComponent.creator_ent = self.entity

    local damagePattern = areaDamageComponent.DamagePattern
    self.timer = damagePattern.area_damage_duration

    areaDamageComponent.area_timer.timeLimit = self.timer

    QueueEvent( "SetTimerRequest", self.entity, "DamageDealing", self.timer )
    self.numberOfActivations = self.numberOfActivations - 1
    self.activated = true
    self.data:SetFloat("is_activated", 1.0 )
    self.data:SetInt("number_of_activations", self.numberOfActivations )
end

function trap:OnEnteredTriggerEvent(evt)
    self.entitiesInsideCount = self.entitiesInsideCount + 1

    if ( self.activated == false ) then
        self:ActivateTrap()
    end
end

function trap:OnLeftTriggerEvent(evt)
    self.entitiesInsideCount = self.entitiesInsideCount - 1
end


return trap
