require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'harvester_drone' ( base_drone )

local LOCK_TYPE_HARVESTER = "harvester";
SetTargetFinderThrottler(LOCK_TYPE_HARVESTER, 3)

function harvester_drone:__init()
    base_drone.__init(self,self)
end

local function FindBestVegetationEntity(source, entities)
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

function harvester_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.search_type = self.data:GetStringOrDefault("search_type","");

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

function harvester_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function harvester_drone:FindActionTarget()
    if self:GetCurrentStorage() >= self.harvest_storage then
        return INVALID_ID
    end

    local predicate = {
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
            
            if ( EntityService:CompareType( entity, "ground_unit" ) ) then
            
                return false
            end

            return true
        end
    };

    local owner = self:GetDroneOwnerTarget();
    if not HealthService:IsAlive( owner ) then
        return INVALID_ID
    end

    if IsRequestThrottled(LOCK_TYPE_HARVESTER) then
        return INVALID_ID
    end

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, predicate );

    local target = FindBestVegetationEntity( self.entity, entities );
    if target ~= INVALID_ID then
        EntityService:EnsureGatherableComponent( target )
        self:LockTarget( target, LOCK_TYPE_HARVESTER );
    end

    return target;
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

    local resources = EntityService:GetGatherableResources(target);
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

    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", math.max(0.1, (current_storage + change_amount) / self.harvest_storage ) );

    return change_amount;
end

function harvester_drone:ClearStorage()
    self.storage = {}
    EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0.1 );
end

function harvester_drone:OnHarvestExecute(state, dt)
    local max_change_amount = ( self.harvest_storage / self.harvest_duration ) * dt;

    local target = self:GetDroneActionTarget();

    if not EntityService:IsAlive( target ) then
        return state:Exit()
    end

    for resource, _ in pairs( self.storage ) do
        local resourceAmount = EntityService:GetGatherResourceAmount(target, resource);

        local harvestAmount = self:UpdateResourceStorage( resource, math.min( resourceAmount, max_change_amount ) );
        if harvestAmount > 0.0 then
            EntityService:ChangeGatherResourceAmount(target, resource, resourceAmount - harvestAmount );
        else
           state:Exit()
        end
    end
end

function harvester_drone:OnHarvestExit()
    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive( target ) then
        local resources = EntityService:GetGatherableResources(target);
        if #resources == 0 then
            EntityService:RemoveComponent(target, "GatherResourceComponent")
            EntityService:RemoveComponent(target, "LootComponent")

            local scannableComponent = EntityService:GetComponent( target, "ScannableComponent" )
            if ( scannableComponent ~= nil ) then

                ItemService:ScanEntityByPlayer( target, self.data:GetIntOrDefault( "owner", 0) )

                EntityService:RemoveComponent( target, "ScannableComponent" )
                EffectService:SpawnEffect( target, "effects/loot/specimen_extracted")
            end

            EntityService:DissolveEntity(target, 2.0)
        end
    end

    EffectService:DestroyEffectsByGroup(self.entity, "work");

    self:UnlockAllTargets();
    self:SetTargetActionFinished();
end

return harvester_drone;