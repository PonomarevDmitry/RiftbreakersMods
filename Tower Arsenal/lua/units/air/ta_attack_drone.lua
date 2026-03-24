require("lua/utils/string_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'ta_attack_drone' ( base_drone )

function ta_attack_drone:__init()
	base_drone.__init(self,self)
end

local DRONE_MIN_ATTACK_DURATION = 0.5

function ta_attack_drone:FillInitialParams()
    self.team = EntityService:GetTeam( self.entity );

    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end

    self.target_resisted_damage = {}
    self.target_resisted_timeout = self.data:GetIntOrDefault("target_resisted_timeout", 5) * 1000

    self.target_aggresive_only = self.data:GetIntOrDefault("target_aggresive_only", 0)
    self.drone_target = self.drone_target or INVALID_ID
    self.found_drone_target = self.found_drone_target or INVALID_ID

    self.attack_start_timer = nil
    self.attack_stop_timer = nil

    self.non_action_timeout = RandFloat(1.5,4.5)

    --if EntityService:GetComponent( self.entity, "TurretComponent") ~= nil then
    --    self.weapon_controller = {
    --        ShootAtTarget   = ta_attack_drone.TurretWeaponControllerShootAtTarget,
    --        StopShooting    = ta_attack_drone.TurretWeaponControllerStopShooting
    --    }
    --else
        self.weapon_controller = {
            ShootAtTarget   = ta_attack_drone.DefaultWeaponControllerShootAtTarget,
            StopShooting    = ta_attack_drone.DefaultWeaponControllerStopShooting
        }
    --end
end

function ta_attack_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("attack", { execute="OnAttackExecute", interval=0.033 });
    self.fsm:ChangeState("attack")

    WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function ta_attack_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function ta_attack_drone:IsTargetValid(target, alert_mode)
    if target == INVALID_ID then
        return false
    end

    if not alert_mode then
        if self.target_resisted_damage[ target ] ~= nil then
            return self.target_resisted_damage[ target ] < GetLogicTime()
        end

        if EntityService:GetDistance2DBetween( target, self.target_finder.entity ) > self.search_radius then
            return false
        end
    end

    return HealthService:IsAlive( target )
end

function ta_attack_drone:OnTargetDamageResistedEvent(evt)
    if evt:GetOwner() ~= self.entity and evt:GetCreator() ~= self.entity then
        return
    end

    if evt:GetPartialResist() then
        return
    end

    local target = evt:GetEntity()
    self.target_resisted_damage[ target ] = GetLogicTime() + self.target_resisted_timeout
end

function ta_attack_drone:SetCurrentTarget( target )
    if self.drone_target ~= INVALID_ID then
        self:UnregisterHandler(self.drone_target, "DamageResistedEvent", "OnTargetDamageResistedEvent")
    end

    self.drone_target = target
    if target ~= INVALID_ID then
        self:RegisterHandler(target, "DamageResistedEvent", "OnTargetDamageResistedEvent")
        self.target_resisted_damage[ target ] = nil
    end

    UnitService:SetCurrentTarget(self.entity, self.target_finder.name, self.drone_target)
end

function ta_attack_drone:OnTargetHasChangedEvent(evt)
    if not self.target_finder or evt:GetTag() ~= self.target_finder.name then
        return
    end

    if not self.is_enabled then
        return
    end

    self.found_drone_target = evt:GetTarget()
end

function ta_attack_drone:FindActionTarget()
    self:EnsureTargetFinder()

    return self.drone_target
end

function ta_attack_drone:OnAttackExecute(state, dt)
    local is_current_target_valid = self:IsTargetValid( self.drone_target );
    local is_next_target_valid = self:IsTargetValid( self.found_drone_target );

    local attack_duration = GetLogicTime() - (self.attack_start_timer or 0)
    if is_next_target_valid and attack_duration > DRONE_MIN_ATTACK_DURATION then
        self:SetCurrentTarget(self.found_drone_target)

        self.attack_start_timer = GetLogicTime()
        self.attack_stop_timer = nil
        is_current_target_valid = true
    end

    if is_current_target_valid then
        UnitService:SetCurrentTarget(self.entity, "action", self.drone_target )
    elseif self:IsTargetValid( self.drone_target, true ) or self:IsTargetValid( self.found_drone_target, true ) then
        UnitService:SetCurrentTarget(self.entity, "action", self:GetDroneOwnerTarget() )
    end

    if is_current_target_valid then
        self.weapon_controller.ShootAtTarget( self, self.drone_target )
    elseif self:GetDroneActionTarget() ~= INVALID_ID then
        self.weapon_controller.StopShooting( self )
        self.drone_target = INVALID_ID
    
        self.attack_start_timer = nil
        if self.attack_stop_timer == nil then
            self.attack_stop_timer = GetLogicTime()
        else
            local idle_duration = GetLogicTime() - (self.attack_stop_timer or 0)
            if idle_duration > self.non_action_timeout then
                self.attack_stop_timer = nil
                self:SetTargetActionFinished();
            end
        end
    end
end

function ta_attack_drone:OnRelease()
    if not self.target_finder then
        return
    end

    if EntityService:IsAlive(self.target_finder.entity) then
        UnitService:RemoveFindTargetRequest( self.target_finder.entity, self.target_finder.name );
    end
end

function ta_attack_drone:EnsureTargetFinder()
    if not self.target_finder then
        local owner = self:GetDroneOwnerTarget()
        self:RegisterHandler(owner, "TargetHasChangedEvent", "OnTargetHasChangedEvent")

        self.target_finder = { name = "ta_attack_drone##" .. tostring( self.entity ), entity = owner }

        if self.target_aggresive_only then
            UnitService:CreateCustomFindTargetRequest( owner, self.target_finder.name, self.search_radius * 1.0, "hostility", "ground_unit", "AggressiveTargetFinder" );
        else
            UnitService:CreateFindTargetRequest( owner, self.target_finder.name, self.search_radius * 1.0, "hostility", "ground_unit" );
        end
    end
end

function ta_attack_drone:DefaultWeaponControllerShootAtTarget( target )
    WeaponService:RotateWeaponMuzzleToTarget( self.entity, self.drone_target )

    if self.is_landing or self.is_lifting then
        return true
    end

    local is_shooting = WeaponService:IsShooting( self.entity );
    if is_shooting and ( self.is_landing or self.is_lifting ) then
        WeaponService:StopShoot(self.entity);
        return true
    end

    EntityService:LookAt( self.entity, self.drone_target, true )

    if not is_shooting and EntityService:HasInArc( self.entity, self.drone_target, -45.0, 45.0 ) then
        WeaponService:StartShoot( self.entity );
    end

    return true;
end

function ta_attack_drone:DefaultWeaponControllerStopShooting()
    WeaponService:StopShoot(self.entity);
end

function ta_attack_drone:TurretWeaponControllerShootAtTarget( target )
end

function ta_attack_drone:TurretWeaponControllerStopShooting()
end

return ta_attack_drone;