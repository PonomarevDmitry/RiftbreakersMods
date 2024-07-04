require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/throttler_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'loot_collector_drone' ( base_drone )

local LOCK_TYPE_LOOT_DRONE = "loot_collector";
SetTargetFinderThrottler(LOCK_TYPE_LOOT_DRONE, 3)

function loot_collector_drone:__init()
    base_drone.__init(self,self)
end

local function GetPlayerForEntity( entity )
    if PlayerService.GetPlayerForEntity then
        return PlayerService:GetPlayerForEntity( entity )
    end

    return 0
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

    self.loot_picker = EntityService:SpawnAndAttachEntity( "units/drones/drone_loot_collector_picker", self.entity, "" )
    self.is_working = false

    EntityService:SetScale( self.loot_picker, self.pickup_radius, 2.0,  self.pickup_radius );

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState("updater", { execute = "OnUpdate", interval = 0.1 })
    self.fsm:ChangeState("updater")
end

function loot_collector_drone:CollectLootEntity( loot_entity )
    local owner = self:GetDroneOwnerTarget()
    local pawn = PlayerService:GetPlayerControlledEnt(GetPlayerForEntity(owner))

    if self:ValidateTarget( loot_entity, pawn ) then
        EffectService:SpawnEffects(loot_entity, "loot_collect")
        ItemService:FlyItemToInventory(pawn, loot_entity)

        return true
    end

    return false
end

function loot_collector_drone:OnEnteredTriggerEvent( evt )
    self:CollectLootEntity(evt:GetOtherEntity())
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

    local terrainHeight = EnvironmentService:GetTerrainHeight(position)

    if ( position.y ~= terrainHeight ) then

        position.y = EnvironmentService:GetTerrainHeight(position)

        EntityService:SetWorldPosition(self.loot_picker, position)
    end

    local loot_target = self:GetDroneActionTarget()
    if EntityService:IsAlive(loot_target) and self.is_enabled then
        self:EnableEffect()

        if EntityService:GetDistance2DBetween(self.entity, loot_target) < self.pickup_radius then
            self:CollectLootEntity(loot_target)
        end
    else
	    self:UnlockAllTargets()
        loot_target = self:FindActionTarget()
        UnitService:SetCurrentTarget( self.entity, "action", loot_target );
    end

    if not self:ValidateTarget( loot_target ) then
        self:SetTargetActionFinished()
        self:DisableEffect()

        self:TryFindNewTarget()
    end
end

function loot_collector_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function loot_collector_drone:ValidateTarget( entity, pawn )
    if not EntityService:IsAlive(entity) or not self.is_enabled then
        return false
    end

    local test_owner = pawn or PlayerService:GetPlayerControlledEnt(GetPlayerForEntity(self:GetDroneOwnerTarget()))
    local test_entity = EntityService:GetParent( entity )
    if test_entity == INVALID_ID then
        test_entity = entity
    end

    if EntityService:GetComponent( test_entity, "PhysicsComponent") == nil then
        return false
    end

    return ItemService:CanFitResourceGiver( test_owner,test_entity )
end

function loot_collector_drone:FindActionTarget()
    local owner = self:GetDroneOwnerTarget()
    if not EntityService:IsAlive( owner ) then
        return INVALID_ID
    end

    local pawn = PlayerService:GetPlayerControlledEnt(GetPlayerForEntity(owner))

    if IsRequestThrottled(LOCK_TYPE_LOOT_DRONE) then
        return INVALID_ID
    end

    self.predicate = self.predicate or {
        signature="BlueprintComponent,IdComponent,ParentComponent",
        filter = function(entity)
            local entity_name = EntityService:GetName(entity);
            if entity_name ~= "#loot#" then
                return false;
            end

            local target = EntityService:GetParent( entity )
            if target == INVALID_ID then
                return false
            end

            if self:IsTargetLocked(target, LOCK_TYPE_LOOT_DRONE) then
                return false
            end

            return self:ValidateTarget( entity, pawn)
        end
    };

    local pointEntity = self:GetDroneFindCenterPoint()

    local entities = FindService:FindEntitiesByPredicateInRadius( pointEntity, self.search_radius, self.predicate );

    local item = FindFarthestEntity( owner, entities )

    local target = EntityService:GetParent( item )
    if target ~= INVALID_ID then
        self:LockTarget( target, LOCK_TYPE_LOOT_DRONE )
        self:EnableEffect()
    end

    return target
end

function loot_collector_drone:OnDroneDisabled()
    self:DisableEffect()
end

function loot_collector_drone:OnDroneTargetAction( target )
    self:SetTargetActionFinished()

    self:TryFindNewTarget()
end

function loot_collector_drone:GetDroneFindCenterPoint()

    local result = self:GetDroneOwnerTarget()

    local database = EntityService:GetDatabase( result )

    if ( database and database:HasInt("center_point_entity") and EntityService:HasComponent( result, "BuildingComponent" ) ) then

        local pointEntity = database:GetIntOrDefault("center_point_entity", INVALID_ID) or INVALID_ID

        if ( pointEntity ~= nil and pointEntity ~= INVALID_ID and EntityService:IsAlive( pointEntity ) ) then

            result = pointEntity
        end
    end

    return result
end

function loot_collector_drone:OnOwnerDistanceCheckExecute()
    local owner = self:GetDroneOwnerTarget()
    if not EntityService:IsAlive(owner) then
        return
    end

    local pointEntity = self:GetDroneFindCenterPoint()

    local distance, closestPosition = GetDistanceAndClosestPositionToLineSegment(self.entity, owner, pointEntity)

    if self.search_radius and distance > self.search_radius * 2.0 and EntityService:GetComponent(self.entity, "IsVisibleComponent") == nil then

        if self.is_enabled then
            QueueEvent( "DisableDroneRequest", self.entity )
            QueueEvent( "EnableDroneRequest", self.entity )
        end

        local target_position = closestPosition
        target_position.y = EntityService:GetPositionY(self.entity)

        EntityService:Teleport(self.entity, target_position)
        QueueEvent( "FadeEntityInRequest", self.entity, 0.3 )
    end

    local action_target = self:GetDroneActionTarget()
    if action_target ~= INVALID_ID and not EntityService:IsAlive(action_target) then
        self:SetTargetActionFinished()

        self:TryFindNewTarget()
    end
end

function loot_collector_drone:TryFindNewTarget()
    self:UnlockAllTargets()
    local target = self:FindActionTarget();
    if target ~= INVALID_ID then
        UnitService:SetCurrentTarget( self.entity, "action", target );
        UnitService:EmitStateMachineParam(self.entity, "action_target_found")
        UnitService:SetStateMachineParam( self.entity, "action_target_valid", 1)
    end
end

return loot_collector_drone;