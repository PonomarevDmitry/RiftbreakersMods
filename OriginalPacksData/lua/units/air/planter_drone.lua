require("lua/utils/string_utils.lua")
require("lua/utils/throttler_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'planter_drone' ( base_drone )

local LOCK_TYPE_PLANT = "plant";
local LOCK_TYPE_CULTIVATE = "cultivate";

SetTargetFinderThrottler(LOCK_TYPE_PLANT, 3)

function planter_drone:__init()
	base_drone.__init(self,self)
end

local function RandPosition( position )
	position.x = position.x + RandFloat( -0.5, 0.5)
	position.z = position.z + RandFloat( -0.5, 0.5)
	return position
end

function planter_drone:FillInitialParams()
    self.plant_radius = self.data:GetFloatOrDefault( "drone_search_radius", self.data:GetFloat("plant_radius") );
    self.plant_time = self.data:GetFloat("plant_time");
    self.plant_marker = self.data:GetString("plant_marker");
    self.plant_effect = self.data:GetString("plant_effect");

    self.team = EntityService:GetTeam( self.entity );
end

function planter_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("plant", { enter="OnPlantEnter", exit="OnPlantExit" } );
    self.fsm:AddState("cultivate", { enter="OnCultivateEnter", exit="OnCultivateExit", duration=10 } );
end

function planter_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function planter_drone:FindActionTarget()
    if self.disable_drone then
        self.disable_drone = false
        base_drone._OnDisableDroneRequest(self, nil)
        return INVALID_ID
    end

    local owner = self:GetDroneOwnerTarget();
    if not HealthService:IsAlive( owner ) then
        return INVALID_ID
    end

    local cultivated_target = self.data:GetStringOrDefault("cultivate_target", "");
    if cultivated_target ~= "" then
        local target = FindService:FindEntityByName(cultivated_target)
        if target ~= INVALID_ID then
            if self:IsTargetLocked( target, LOCK_TYPE_CULTIVATE ) then
                return INVALID_ID
            end

            self:LockTarget(target, LOCK_TYPE_CULTIVATE);
        end

        return target;
    end

    local result = {}
    
    if self.data:GetStringOrDefault("plant_prefab", "") ~= "" then
        if IsRequestThrottled(LOCK_TYPE_PLANT) then
            return INVALID_ID
        end
        
        result = FindService:FindEmptyCultivatorSpotInRadius( owner, self.plant_radius, "vegetation", "floor,desert_floor,acid_floor,magma_floor");
    elseif self.data:GetStringOrDefault("plant_blueprint", "") ~= "" then
        result = FindService:FindEmptySpotInRadius( owner, self.plant_radius, "vegetation", "floor,desert_floor,acid_floor,magma_floor");
    end

    if not result.first then
        return INVALID_ID;
    end

    local position = result.second
    local marker = EntityService:SpawnEntity(self.plant_marker, position, self.team );
    EntityService:Rotate(marker, 0.0, 1.0, 0.0, RandFloat(0.0, 360.0));

    self:LockTarget(marker, LOCK_TYPE_PLANT);

    return marker;
end

function planter_drone:OnDroneTargetAction( target )
    local cultivated_target = self.data:GetStringOrDefault("cultivate_target", "");
    if cultivated_target ~= "" then
        self.fsm:ChangeState( "cultivate" )
    else
        self.fsm:ChangeState( "plant" )
    end

    return false;
end

function planter_drone:OnPlantEnter(state)
    state:SetDurationLimit(self.plant_time)
    EffectService:AttachEffects(self.entity, "work");
end

function planter_drone:OnPlantExit()
    EffectService:DestroyEffectsByGroup(self.entity, "work");

    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive(target) then 
        local plant_blueprint = self.data:GetStringOrDefault("plant_blueprint", "");
        local plant_prefab = self.data:GetStringOrDefault("plant_prefab", "");

        if plant_blueprint ~= "" then
            EntityService:RemovePropsInEntityBounds( target )

            local entity = EntityService:SpawnEntity(plant_blueprint, target, "" );
            EntityService:EnableVegetationChain( entity );
            EffectService:SpawnEffect(entity, self.plant_effect );
        elseif plant_prefab ~= "" then
            local owner = self:GetDroneOwnerTarget();

            local pos = EntityService:GetPosition(target)
            
            local entities = BuildingService:SpawnCultivatorSaplingsAt( owner, pos );
            for entity in Iter(entities) do
                EffectService:SpawnEffect(entity, self.plant_effect );
            end
        end
    end

    self:UnlockAllTargets();
    self:SetTargetActionFinished();
end

function planter_drone:OnCultivateEnter(state)
    state:SetDurationLimit(10.0)
    EffectService:AttachEffects(self.entity, "work");
end

function planter_drone:OnCultivateExit()
    EffectService:DestroyEffectsByGroup(self.entity, "work");

    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive(target) then
        local owner = self:GetDroneOwnerTarget();
        QueueEvent("LuaGlobalEvent", owner, "CultivationEnded", {})
        QueueEvent("LuaGlobalEvent", target, "CultivationEnded", {})
    end

    self:UnlockAllTargets();
    self:SetTargetActionFinished();
end

function planter_drone:UnlockTarget(target, type)
    if base_drone.UnlockTarget(self, target, type) and type == LOCK_TYPE_PLANT then
        EntityService:RemoveEntity(target);
    end
end

function planter_drone:_OnEnableDroneRequest( evt )
    self.disable_drone = false
    base_drone._OnEnableDroneRequest( self, evt )
end

function planter_drone:_OnDisableDroneRequest( evt )
    self.disable_drone = true
end

return planter_drone;