require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")
require("lua/utils/throttler_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'repellent_drone' ( base_drone )

local LOCK_TYPE_REPELLENT = "repellent";
SetTargetFinderThrottler(LOCK_TYPE_REPELLENT, 3)

function repellent_drone:__init()
	base_drone.__init(self,self)
end

function repellent_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.search_blueprint = self.data:GetStringOrDefault("search_blueprint","");
    self.spraying_time = self.data:GetFloat("spraying_time");
end

function repellent_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("work", { enter="OnWorkEnter", execute="OnWorkExecute", exit="OnWorkExit", interval=0.5 } );
end

function repellent_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function repellent_drone:FindActionTarget()
    local owner = self:GetDroneOwnerTarget();
    if not EntityService:IsAlive( owner ) then
        return INVALID_ID
    end

    if IsRequestThrottled(LOCK_TYPE_REPELLENT) then
        return INVALID_ID
    end

    self.predicate = self.predicate or {
        blueprint=self.search_blueprint,
        filter = function(entity) 
            if self:IsTargetLocked(entity, LOCK_TYPE_REPELLENT) then
                return false
            end
            return true
        end
    };

    local entities = FindService:FindEntitiesByPredicateInRadius( owner, self.search_radius, self.predicate );
    local target = entities[ RandInt(1, #entities) ] or INVALID_ID
    if target ~= INVALID_ID then
        self:LockTarget( target, LOCK_TYPE_REPELLENT );
    end

    return target;
end

function repellent_drone:OnDroneTargetAction( target )
    self.fsm:ChangeState("work")
end

function repellent_drone:OnWorkEnter(state)
    state:SetDurationLimit(self.spraying_time)

    EffectService:AttachEffects(self.entity, "work");
end

function repellent_drone:OnWorkExecute(state, dt)
    local target = self:GetDroneActionTarget();
    if not EntityService:IsAlive( target ) then
        return state:Exit()
    end
end

function repellent_drone:OnWorkExit()
    EffectService:DestroyEffectsByGroup(self.entity, "work");

    self:UnlockAllTargets();
    self:SetTargetActionFinished();
end

return repellent_drone;