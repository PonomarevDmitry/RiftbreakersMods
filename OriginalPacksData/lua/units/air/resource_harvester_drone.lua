require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/throttler_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'harvester_drone' ( base_drone )

local LOCK_TYPE_HARVESTER = "harvester";
SetTargetFinderThrottler(LOCK_TYPE_HARVESTER, 3)

g_allocated_resource_drones = {}

local function GetGatherableResources( target, is_vegetation )
    if is_vegetation then
        return EntityService:GetGatherableResources(target);
    else
        local result = EntityService:GetResourceAmount(target)
        if result.second > 0 then
            return { result }
        end
    end

    return {}
end

local function GetGatherableResourceAmount( target, resource, is_vegetation )
    if is_vegetation then
        return EntityService:GetGatherResourceAmount(target, resource);
    end

    return EntityService:GetResourceAmount(target).second
end

local function ChangeGatherableResourceAmount( target, resource, amount, is_vegetation )
    if is_vegetation then
        return EntityService:ChangeGatherResourceAmount(target, resource, amount );
    end

    EntityService:ChangeResourceAmount(target, amount)
end

function harvester_drone:__init()
	base_drone.__init(self,self)
end

function harvester_drone:FindBestVegetationEntity(owner, source)
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

            local lootComponent = EntityService:GetComponent(entity, "LootComponent")
            if not lootComponent or not reflection_helper( lootComponent ).is_gatherable then
                return false
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

function harvester_drone:FindResourceVeinEntity(owner, source)
    self.predicate = self.predicate or {
        type=self.search_type,
        signature="ResourceComponent,GridMarkerComponent",
        filter = function(entity) 
            if self:IsTargetLocked(entity, LOCK_TYPE_HARVESTER) then
                return false
            end

            if IndexOf(self.exclude_targets, entity) ~= nil then
                return false
            end

            local position = EntityService:GetPosition(entity)
            if FindService:IsGridMarkedWithLayer(position, "OwnerLayerComponent") then
                return false
            end

            local result = EntityService:GetResourceAmount(entity)
            if not PlayerService:IsResourceUnlocked(result.first) then
                return false
            end

            return true
        end
    };

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, self.predicate );
    if #entities > 0 then
        local parents = {}
        for entity in Iter(entities) do
            table.insert(parents, { entity = entity, parent = EntityService:GetParent(entity), distance = EntityService:GetDistanceBetween(owner,entity)})
        end

        local sorter = function(lhs,rhs)
            return #(g_allocated_resource_drones[lhs.parent] or { distance = 0.0 }) < #(g_allocated_resource_drones[rhs.parent] or {})
        end

        table.sort( parents, sorter )

        return parents[1].entity
    end

    return INVALID_ID
end

function harvester_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.search_type = self.data:GetStringOrDefault("search_type","");

    self.harvest_vegetation = self.data:GetIntOrDefault("harvest_vegetation", 1 ) == 1;
    self.harvest_storage = self.data:GetFloat("harvest_storage");
    self.harvest_duration = self.data:GetFloat("harvest_time");
    self.unload_duration = self.data:GetFloat("unload_time");
    self.exclude_targets = self.exclude_targets or {};

    if self.debug == nil then
        self.debug = self:CreateStateMachine();
        self.debug:AddState("debug", { execute="OnDebugExecute" } );
    end
end

function harvester_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("harvest", { enter="OnHarvestEnter", execute="OnHarvestExecute", exit="OnHarvestExit", interval=0.5 } );
    self.fsm:AddState("unload", { enter="OnUnloadEnter", execute="OnUnloadExecute", exit="OnUnloadExit", interval=0.5 } );

    self:ClearStorage();
end

function harvester_drone:OnDebugExecute()
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

function harvester_drone:LockTarget( target, lock_type )
    base_drone.LockTarget( self, target, lock_type )

    if self.harvest_vegetation then
        return
    end

    local parent = EntityService:GetParent(target)
    if parent ~= INVALID_ID then
        target = parent
    end

    if g_allocated_resource_drones[ target ] == nil then
        g_allocated_resource_drones[ target ] = {}
    end

    table.insert(g_allocated_resource_drones[ target ], self.entity )
end

function harvester_drone:UnlockTarget( target, lock_type )
    base_drone.UnlockTarget( self, target, lock_type )

    if self.harvest_vegetation then
        return
    end

    local parent = EntityService:GetParent(target)
    if parent ~= INVALID_ID then
        target = parent
    end

    if g_allocated_resource_drones[ target ] == nil then
        g_allocated_resource_drones[ target ] = {}
    end

    table.remove(g_allocated_resource_drones[ target ], self.entity )
end

function harvester_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function harvester_drone:FindActionTarget()
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

    if self.harvest_vegetation then
        local target = self:FindBestVegetationEntity(owner, self.entity)
        if target ~= INVALID_ID then
            EntityService:EnsureGatherableComponent( target )
            self:LockTarget( target, LOCK_TYPE_HARVESTER );
        end

        return target;
    else
        local target = self:FindResourceVeinEntity(owner, self.entity)
        if target ~= INVALID_ID then
            self:LockTarget( target, LOCK_TYPE_HARVESTER );
        end

        return target;
    end
end

function harvester_drone:OnDroneOwnerAction( target )
    self.fsm:ChangeState("unload")
end

function harvester_drone:OnDroneTargetAction( target )
    self.fsm:ChangeState("harvest")
end

function harvester_drone:OnUnloadEnter(state)
    state:SetDurationLimit(self.unload_duration)

    for resource, amount in pairs( self.storage ) do
        if not PlayerService:IsResourceUnlocked( resource ) then
            self:UpdateResourceStorage(resource, -amount);
        end
    end
end

function harvester_drone:UnloadResource( resource, amount )
    local owner = self:GetDroneOwnerTarget();
    if owner ~= INVALID_ID then
        local database = EntityService:GetDatabase( owner )
        if database ~= nil then
            local value = database:GetFloatOrDefault("harvested_resources." .. resource, 0.0)
            database:SetFloat("harvested_resources." .. resource, value + amount )
        end
    end

    PlayerService:AddResourceAmount(resource, amount);

    self:UpdateResourceStorage(resource, -amount);
end

function harvester_drone:OnUnloadExecute(state, dt)
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

function harvester_drone:OnUnloadExit(state)
    for resource, amount in pairs( self.storage ) do
        self:UnloadResource(resource, amount )
    end

    self:ClearStorage();

    self:SetOwnerActionFinished();
    Clear(self.exclude_targets)
end

function harvester_drone:OnHarvestEnter(state)
    if g_debug_resource_harvester then
        self.debug:ChangeState("debug")
    else
        self.debug:Deactivate()
    end
    state:SetDurationLimit(self.harvest_duration)

    local target = self:GetDroneActionTarget();
    Insert(self.exclude_targets, target)

    local resources = GetGatherableResources( target, self.harvest_vegetation )
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

function harvester_drone:GetCurrentStorage()
    local current_storage = 0;
    for resource, amount in pairs( self.storage ) do
        current_storage = current_storage + amount;
    end

    return current_storage
end

function harvester_drone:UpdateResourceStorage( resource, change_amount )
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

function harvester_drone:ClearStorage()
    self.storage = {}
    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.5 );
end

function harvester_drone:OnHarvestExecute(state, dt)
    local max_change_amount = ( self.harvest_storage / self.harvest_duration ) * dt;

    local target = self:GetDroneActionTarget();

    if not EntityService:IsAlive( target ) then
        return state:Exit()
    end

    for resource, _ in pairs( self.storage ) do
        local resourceAmount = GetGatherableResourceAmount(target, resource, self.harvest_vegetation);

        local harvestAmount = self:UpdateResourceStorage( resource, math.min( resourceAmount, max_change_amount ) );
        if harvestAmount > 0.0 then
            ChangeGatherableResourceAmount( target, resource, resourceAmount - harvestAmount, self.harvest_vegetation )
        else
           state:Exit()
        end

    end
end

function harvester_drone:OnHarvestExit()
    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive( target ) then
        local resources = GetGatherableResources(target, self.harvest_vegetation);
        if #resources == 0 then
            EntityService:RemoveComponent(target, "GatherResourceComponent")
            EntityService:RemoveComponent(target, "LootComponent")
            EntityService:RemoveComponent(target, "ResourceComponent")

            EntityService:DissolveEntity(target, 2.0)
        end
    end

    EffectService:DestroyEffectsByGroup(self.entity, "work");

    self:UnlockAllTargets();
    self:SetTargetActionFinished();
end

return harvester_drone;