require("lua/utils/string_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'loot_collector_drone' ( base_drone )

function loot_collector_drone:__init()
	base_drone.__init(self,self)
end

function FindFarthestEntity( source, entities )
    local closest = {
        entity = INVALID_ID,
        distance = nil
    };

    for entity in Iter( entities ) do
        local distance = EntityService:GetDistanceBetween( source, entity );
        if closest.entity == INVALID_ID or distance > closest.distance then
            closest.entity = entity;
            closest.distance = distance;
        end
    end

    return closest.entity;
end

function loot_collector_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.pickup_radius = self.data:GetFloat("pickup_radius")
end

function loot_collector_drone:OnInit()
    self:FillInitialParams();

    self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )

    self.loot_picker = EntityService:SpawnAndAttachEntity( "units/drones/drone_player_loot_collector_picker", self.entity, "" )
    self.is_working = false

    EntityService:SetScale( self.loot_picker, self.pickup_radius, 2.0,  self.pickup_radius );

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState("updater", { execute = "OnUpdate", interval = 1.0 })
    self.fsm:ChangeState("updater")
end

function loot_collector_drone:OnEnteredTriggerEvent( evt )
    local owner = self:GetDroneOwnerTarget()

    if ItemService:CanFitResourceGiver( owner, evt:GetOtherEntity() ) then
        EffectService:SpawnEffects(evt:GetOtherEntity(), "loot_collect")
        ItemService:FlyItemToInventory(owner, evt:GetOtherEntity())
    end
end

function loot_collector_drone:EnableEffect()
    if self.is_working then
        return
    end

    self.is_working = true
    EffectService:AttachEffects(self.entity, "working")
end

function loot_collector_drone:DisableEffect()
    if not self.is_working then
        return
    end 

    self.is_working = false
    EffectService:DestroyEffectsByGroup(self.entity, "working")
end

function loot_collector_drone:OnUpdate()
    local position = EntityService:GetPosition(self.loot_picker)
    position.y = EnvironmentService:GetTerrainHeight(position)

    EntityService:SetWorldPosition(self.loot_picker, position)

    local loot_target = self:GetDroneActionTarget()
    if EntityService:IsAlive(loot_target) then
        self:EnableEffect()
    else
        self:DisableEffect()
    end
end

function loot_collector_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function loot_collector_drone:FindActionTarget()
    local owner = self:GetDroneOwnerTarget()
    local predicate = {
        signature="BlueprintComponent,IdComponent,ParentComponent",
        filter = function(entity)
            local entity_name = EntityService:GetName(entity);
            if entity_name ~= "#loot#" then
                return false;
            end

            return ItemService:CanFitResourceGiver( owner, EntityService:GetParent( entity ) );
        end
    };

    local owner = self:GetDroneOwnerTarget()

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, predicate );
    
    local item = FindFarthestEntity( owner, entities )
    local target = EntityService:GetParent( item )
    if target ~= INVALID_ID then
        self:EnableEffect()
    end

    return target
end

function loot_collector_drone:OnDroneTargetAction( target )
    self:SetTargetActionFinished()
end

return loot_collector_drone;