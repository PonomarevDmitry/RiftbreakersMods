require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/throttler_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'player_resource_harvester_drone' ( base_drone )

local LOCK_TYPE_HARVESTER = "harvester";
SetTargetFinderThrottler(LOCK_TYPE_HARVESTER, 3)

g_allocated_resource_drones = g_allocated_resource_drones or {}

function player_resource_harvester_drone:__init()
    base_drone.__init(self,self)
end

function player_resource_harvester_drone:FindBestVegetationEntity(owner, source)
    self.predicate = self.predicate or {
        type=self.search_type,
        signature="LootComponent",
        filter = function(entity)
            if self:IsTargetLocked(entity, LOCK_TYPE_HARVESTER) then
                return false
            end

            if IndexOf(self.exclude_targets, entity) ~= nil then
                return false
            end


            if not EntityService:IsInFinalVegetationChainPhase( entity ) then
                return false
            end

            local lootComponent = EntityService:GetConstComponent(entity, "LootComponent")
            if not lootComponent or not reflection_helper( lootComponent ).is_gatherable then
                return false
            end

            local isUnitEntity = EntityService:HasComponent( entity, "AIUnitComponent" )
                                    or EntityService:HasComponent( entity, "NeutralUnitComponent" )
                                    or EntityService:HasComponent( entity, "WaveUnitComponent" )
                                    or EntityService:HasComponent( entity, "AggressiveStateComponent" )
                                    or EntityService:HasComponent( entity, "NotAggressiveStateComponent" )
                                    ;

            if ( isUnitEntity ) then

                local isAlive = HealthService:IsAlive( entity )

                if ( isAlive ) then
                    return false
                end
            end

            return true
        end
    };

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, self.predicate );

    local best = {
        entity = INVALID_ID,
        distance = nil,
        index = -1
    };

    for entity in Iter( entities ) do
        local name = EntityService:GetBlueprintName( entity );

        local index = -1;
        if ( string.find( name, "very_large") ) then
            index = 5
        elseif ( string.find( name, "large") ) then
            index = 4
        elseif ( string.find( name, "big") ) then
            index = 4
        elseif ( string.find( name, "medium") ) then
            index = 3
        elseif ( string.find( name, "very_small") ) then
            index = 1
        elseif ( string.find( name, "small") ) then
            index = 2
        else
            index = 0
        end
        local distance = EntityService:GetDistanceBetween( source, entity );

        if best.entity == INVALID_ID or index > best.index then
            best.entity = entity
            best.distance = distance;
            best.index = index
        elseif index == best.index and best.distance > distance then
            best.entity = entity
            best.distance = distance;
            best.index = index
        end
    end

    return best.entity
end

function player_resource_harvester_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.search_type = self.data:GetStringOrDefault("search_type","");

    self.harvest_vegetation = true;
    self.harvest_storage = self.data:GetFloat("harvest_storage");
    self.harvest_duration = self.data:GetFloat("harvest_time");
    self.unload_duration = self.data:GetFloat("unload_time");
    self.exclude_targets = self.exclude_targets or {}



    --if self.debug == nil then
    --    self.debug = self:CreateStateMachine();
    --    self.debug:AddState("debug", { execute="OnDebugExecute" } );
    --end

    EntityService:FadeEntity( self.entity, DD_FADE_OUT, 0.3 )
            
    self:RegisterHandler( self.entity, "DroneLandingStartedEvent", "_OnDroneLandingStartedEvent" )
    self:RegisterHandler( self.entity, "DroneLandingEndedEvent", "_OnDroneLandingEndedEvent" )
    self:RegisterHandler( self.entity, "DroneLiftingStartedEvent", "_OnDroneLiftingStartedEvent" )
    self:RegisterHandler( self.entity, "DroneLiftingEndedEvent", "_OnDroneLiftingEndedEvent" )
end

function player_resource_harvester_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("harvest", { enter="OnHarvestEnter", execute="OnHarvestExecute", exit="OnHarvestExit", interval=0.5 } );
    self.fsm:AddState("unload", { enter="OnUnloadEnter", execute="OnUnloadExecute", exit="OnUnloadExit", interval=0.5 } );

    self:ClearStorage();
end

function player_resource_harvester_drone:OnDebugExecute()
    local message = "HARVESTED:\n"
    for resource, amount in pairs( self.storage ) do
        message = message .. resource .. " = " .. tostring(amount) .. "\n";
    end

    LogService:DebugText(self.entity,message)

    local target = self:GetDroneActionTarget();
    if target ~= INVALID_ID then
        local message = "GATHERABLE:\n"

        local resources = EntityService:GetGatherableResources(target);
        for i=1,#resources do
            local resource_name = resources[i].first;
            message = message .. resources[i].first .. " = " .. tostring(resources[i].second) .. "\n";
        end

        LogService:DebugText(target, message)
    end
end

function player_resource_harvester_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function player_resource_harvester_drone:FindActionTarget()
    if self:GetCurrentStorage() >= self.harvest_storage then
        return INVALID_ID
    end

    local owner = self:GetDroneOwnerTarget();
    if not EntityService:IsAlive( owner ) then
        return INVALID_ID
    end

    if IsRequestThrottled(LOCK_TYPE_HARVESTER) then
        return INVALID_ID
    end

    local pointEntity = self:GetDroneFindCenterPoint()

    local target = self:FindBestVegetationEntity(pointEntity, self.entity)
    if target ~= INVALID_ID then
        EntityService:EnsureGatherableComponent( target )
        self:LockTarget( target, LOCK_TYPE_HARVESTER );
    end

    return target;
end

function player_resource_harvester_drone:GetDroneFindCenterPoint()

    local result = self:GetDroneOwnerTarget();

    local database = EntityService:GetDatabase( result )

    if ( database and database:HasInt("center_point_entity") and EntityService:HasComponent( result, "BuildingComponent" ) ) then

        local pointEntity = database:GetIntOrDefault("center_point_entity", INVALID_ID) or INVALID_ID

        if ( pointEntity ~= nil and pointEntity ~= INVALID_ID and EntityService:IsAlive( pointEntity ) ) then

            result = pointEntity
        end
    end

    return result
end

function player_resource_harvester_drone:OnDroneOwnerAction( target )
    self.fsm:ChangeState("unload")
end

function player_resource_harvester_drone:OnDroneTargetAction( target )
    self.fsm:ChangeState("harvest")
end

function player_resource_harvester_drone:OnUnloadEnter(state)

    state:SetDurationLimit(self.unload_duration)

    for resource, amount in pairs( self.storage ) do
        if not PlayerService:IsResourceUnlocked( resource ) then
            self:UpdateResourceStorage(resource, -amount);
        end
    end
end

function player_resource_harvester_drone:UnloadResource( resource, amount )

    local databaseSelf = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    local harvestFactor = databaseSelf:GetFloatOrDefault("drone_harvest_factor", 1.0)

    PlayerService:AddResourceAmount(resource, amount * harvestFactor);

    self:UpdateResourceStorage(resource, -amount);
end

function player_resource_harvester_drone:OnUnloadExecute(state, dt)

    local max_change_amount = ( self.harvest_storage / self.unload_duration ) * dt;
    for resource, amount in pairs( self.storage ) do
        local change_amount = max_change_amount;
        if amount < max_change_amount then
            change_amount = amount
        end

        -- local max_player_storage = PlayerService:GetResourceLimit( resource );
        -- local curr_player_storage = PlayerService:GetResourceAmount( resource );

        -- local player_storage = max_player_storage - curr_player_storage;
        -- if change_amount > player_storage then
        --     change_amount = player_storage
        -- end

        -- if change_amount > 0 then
            self:UnloadResource(resource, change_amount);
        --end
    end

    if self:GetCurrentStorage() <= 0.0 then
        state:Exit()
    end
end

function player_resource_harvester_drone:OnUnloadExit(state)

    for resource, amount in pairs( self.storage ) do
        self:UnloadResource(resource, amount )
    end

    self:ClearStorage();

    self:SetOwnerActionFinished();
    Clear(self.exclude_targets)
end

function player_resource_harvester_drone:OnHarvestEnter(state)

    --if g_debug_resource_harvester then
    --    self.debug:ChangeState("debug")
    --else
    --    self.debug:Deactivate()
    --end
    state:SetDurationLimit(self.harvest_duration)

    local target = self:GetDroneActionTarget();

    local isUnitEntity = EntityService:HasComponent( target, "AIUnitComponent" )
                            or EntityService:HasComponent( target, "NeutralUnitComponent" )
                            or EntityService:HasComponent( target, "WaveUnitComponent" )
                            or EntityService:HasComponent( target, "AggressiveStateComponent" )
                            or EntityService:HasComponent( target, "NotAggressiveStateComponent" )
                            ;

    if ( isUnitEntity ) then

        local isAlive = HealthService:IsAlive( target )

        if ( isAlive ) then

            self:UnlockAllTargets()
            self:SetTargetActionFinished()

            self:TryFindNewTarget()

            return state:Exit()
        end
    end

    Insert(self.exclude_targets, target)

    local resources = EntityService:GetGatherableResources(target)
    if #resources == 0 then
        state:Exit()
        return;
    end

    for i=1,#resources do
        local resource_name = resources[i].first;

        local current_amount = self.storage[ resource_name ];
        self.storage[ resource_name ] = current_amount or 0.0
    end

    EffectService:AttachEffects(self.entity, "work");
end

function player_resource_harvester_drone:GetCurrentStorage()
    local current_storage = 0;
    for resource, amount in pairs( self.storage ) do
        current_storage = current_storage + amount;
    end

    return current_storage
end

function player_resource_harvester_drone:UpdateResourceStorage( resource, change_amount )
    local current_storage = self:GetCurrentStorage();

    local storage_left = self.harvest_storage - current_storage
    if  change_amount > storage_left then
        change_amount = storage_left
    end

    local current_amount = self.storage[ resource ];
    self.storage[ resource ] = current_amount + change_amount;

    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", math.max( 0.5, (current_storage + change_amount) / self.harvest_storage ) );

    return change_amount;
end

function player_resource_harvester_drone:ClearStorage()
    self.storage = {}
    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.5 );
end

function player_resource_harvester_drone:OnHarvestExecute(state, dt)

    local max_change_amount = ( self.harvest_storage / self.harvest_duration ) * dt;

    local target = self:GetDroneActionTarget();

    if not EntityService:IsAlive( target ) then
        return state:Exit()
    end

    local isUnitEntity = EntityService:HasComponent( target, "AIUnitComponent" )
                            or EntityService:HasComponent( target, "NeutralUnitComponent" )
                            or EntityService:HasComponent( target, "WaveUnitComponent" )
                            or EntityService:HasComponent( target, "AggressiveStateComponent" )
                            or EntityService:HasComponent( target, "NotAggressiveStateComponent" )
                            ;

    if ( isUnitEntity ) then

        local isAlive = HealthService:IsAlive( target )

        if ( isAlive ) then

            self:UnlockAllTargets()
            self:SetTargetActionFinished()

            self:TryFindNewTarget()

            return state:Exit()
        end
    end

    for resource, _ in pairs( self.storage ) do

        local resourceAmount = EntityService:GetGatherResourceAmount(target, resource)

        local harvestAmount = self:UpdateResourceStorage( resource, math.min( resourceAmount, max_change_amount ) );
        if harvestAmount > 0.0 then

            EntityService:ChangeGatherResourceAmount(target, resource, resourceAmount - harvestAmount )
        else
           state:Exit()
        end

    end
end

function player_resource_harvester_drone:OnHarvestExit()

    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive( target ) then

        local resources = EntityService:GetGatherableResources(target)

        if #resources == 0 then
            EntityService:RemoveComponent(target, "GatherResourceComponent")
            EntityService:RemoveComponent(target, "LootComponent")
            EntityService:RemoveComponent(target, "ResourceComponent")

            local scannableComponent = EntityService:GetComponent( target, "ScannableComponent" )
            if ( scannableComponent ~= nil ) then

                local owner = self:GetDroneOwnerTarget()
                local playerId = self:GetPlayerForEntity(owner)

                local scansCount = 1

                if ( mod_scanner_drone_size_matters and mod_scanner_drone_size_matters == 1 ) then

                    scansCount = self:GetScansCount(target)
                end

                for i=1,scansCount do
                    ItemService:ScanEntityByPlayer( target, playerId )
                end

                EntityService:RemoveComponent( target, "ScannableComponent" )
                
                EffectService:SpawnEffect( target, "effects/loot/specimen_extracted")
            end

            EntityService:DissolveEntity(target, 2.0)
        end
    end

    EffectService:DestroyEffectsByGroup(self.entity, "work");

    self:UnlockAllTargets();
    self:SetTargetActionFinished();

    self:TryFindNewTarget()
end

function player_resource_harvester_drone:GetPlayerForEntity( entity )
    if PlayerService.GetPlayerForEntity then
        return PlayerService:GetPlayerForEntity( entity )
    end

    return 0
end

function player_resource_harvester_drone:GetScansCount( entity )

    local scansCount = 1

    local size = EntityService:GetBoundsSize( entity )

    if ( size.x <= 2.5 ) then
        scansCount = 2
    elseif ( size.x <= 4.5 ) then
        scansCount = 4
    elseif ( size.x <= 9.5 ) then
        scansCount = 8
    else
        scansCount = 20
    end

    return scansCount
end

function player_resource_harvester_drone:TryFindNewTarget()
    local target = self:FindActionTarget();
    if target ~= INVALID_ID then
        UnitService:SetCurrentTarget( self.entity, "action", target )
        UnitService:EmitStateMachineParam(self.entity, "action_target_found")
        UnitService:SetStateMachineParam( self.entity, "action_target_valid", 1)

    else

        local owner = self:GetDroneOwnerTarget()

        UnitService:SetCurrentTarget( self.entity, "owner", owner )
    end
end

function player_resource_harvester_drone:OnOwnerDistanceCheckExecute()
    local owner = self:GetDroneOwnerTarget()
    if not EntityService:IsAlive(owner) then
        return
    end

    local distance = EntityService:GetDistance2DBetween( self.entity, owner )
    if self.search_radius and distance > self.search_radius * 2.0 and EntityService:GetComponent(self.entity, "IsVisibleComponent") == nil then

        if self.is_enabled then
            QueueEvent( "DisableDroneRequest", self.entity )
            QueueEvent( "EnableDroneRequest", self.entity )
        end

        local target_position = closestPosition
        target_position.y = EntityService:GetPositionY(self.entity)

        EntityService:Teleport(self.entity, target_position)
        --QueueEvent( "FadeEntityInRequest", self.entity, 0.3 )
        EntityService:FadeEntity( self.entity, DD_FADE_IN, 0.3 )
    end

    local action_target = self:GetDroneActionTarget()
    if action_target ~= INVALID_ID and not EntityService:IsAlive(action_target) then
        self:SetTargetActionFinished()

        self:TryFindNewTarget()
    end
end

function player_resource_harvester_drone:_OnDroneLiftingStartedEvent(evt)

    EntityService:FadeEntity( evt:GetEntity(), DD_FADE_IN, 0.3 )
end

function player_resource_harvester_drone:_OnDroneLandingStartedEvent(evt)
end

function player_resource_harvester_drone:_OnDroneLiftingEndedEvent(evt)
end

function player_resource_harvester_drone:_OnDroneLandingEndedEvent(evt)

    EntityService:FadeEntity( evt:GetEntity(), DD_FADE_OUT, 0.3 )
end

function player_resource_harvester_drone:OnRelease()

    for resource, amount in pairs( self.storage ) do
        self:UnloadResource(resource, amount )
    end

    self:ClearStorage()
end

return player_resource_harvester_drone;