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

    local database = EntityService:GetBlueprintDatabase( self.entity)
    self.numberOfActivations = database:GetInt("number_of_activations")
    self.data:SetInt("number_of_activations", self.numberOfActivations)
    self.damageBlueprint = self.data:GetString("damage_blueprint")
    if ( self.data:HasFloat( "reset_timer")) then
        self.resetTimer = self.data:GetFloat("reset_timer")
    end
    self.entitiesInsideCount = 0
    self.activated = false
    EntityService:CreateComponent( self.entity, "TimerComponent")
end

function trap:OnTimerElapsedEvent(evt)
    if (evt:GetName() ~= "DamageDealing") then
        return
    end
    self.data:SetFloat("is_activated", 0.0 )

    if ( self.numberOfActivations <= 0 ) then
        EntityService:DestroyEntity(self.entity, "default")
        HealthService:SetHealth( self.entity, 0.0 )
    elseif (self.entitiesInsideCount > 0 ) then
        self:ActivateTrap( false)
    else
        EffectService:DestroyEffectsByGroup( self.entity, "activated" ) 
        self.activated = false
    end
end

function trap:ActivateTrap( attachEffects)
    if ( attachEffects ) then
        EffectService:AttachEffects( self.entity, "activated" ) 
    end
    self.damageEnt = EntityService:SpawnAndAttachEntity(self.damageBlueprint, self.entity, EntityService:GetTeam(self.entity) )
    local areaDamageComponent = reflection_helper( EntityService:GetComponent(self.damageEnt, "AreaDamageComponent"))
    areaDamageComponent.owner_ent.id = self.entity
    areaDamageComponent.creator_ent.id = self.entity

    local damagePattern = areaDamageComponent.DamagePattern
    self.timer = damagePattern.area_damage_duration

    areaDamageComponent.area_timer.timeLimit = self.timer
    areaDamageComponent.update_timer.timePassed = areaDamageComponent.update_timer.timeLimit 
    
    QueueEvent( "SetTimerRequest", self.entity, "DamageDealing", self.resetTimer or self.timer )
     
	local unlimitedActivations = ConsoleService:GetConfig("cheat_unlimited_activations") == "1"
    if ( unlimitedActivations == false) then
        self.numberOfActivations = self.numberOfActivations - 1
    end
    self.activated = true
    self.data:SetFloat("is_activated", 1.0 )
    self.data:SetInt("number_of_activations", self.numberOfActivations )
end

function trap:OnEnteredTriggerEvent(evt)
    self.entitiesInsideCount = self.entitiesInsideCount + 1

    if ( self.activated == false ) then
        self:ActivateTrap( true)
    end
end

function trap:OnLeftTriggerEvent(evt)
    self.entitiesInsideCount = self.entitiesInsideCount - 1
end


return trap
