require("lua/utils/string_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'attack_drone' ( base_drone )

function attack_drone:__init()
	base_drone.__init(self,self)
end

function attack_drone:FillInitialParams()
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

    self.attack_start_timer = nil
    self.attack_stop_timer = nil

    self.non_action_timeout = RandFloat(2.0,5.0)

    --if EntityService:GetComponent( self.entity, "TurretComponent") ~= nil then
    --    self.weapon_controller = {
    --        ShootAtTarget   = attack_drone.TurretWeaponControllerShootAtTarget,
    --        StopShooting    = attack_drone.TurretWeaponControllerStopShooting
    --    }
    --else
        self.weapon_controller = {
            ShootAtTarget   = attack_drone.DefaultWeaponControllerShootAtTarget,
            StopShooting    = attack_drone.DefaultWeaponControllerStopShooting
        }
    --end
end

function attack_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("attack", { execute="OnAttackExecute" });
    self.fsm:ChangeState("attack")

	WeaponService:UpdateWeaponStatComponent( self.entity, self.entity )
end

function attack_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function attack_drone:IsTargetValid(target)
    if target == INVALID_ID then
        return false
    end

    if self.target_resisted_damage[ target ] ~= nil then
        return self.target_resisted_damage[ target ] < GetLogicTime()
    end

    if EntityService:GetDistance2DBetween( target, self.target_finder.entity ) > self.search_radius then
        return false
    end

    return HealthService:IsAlive( target )
end

function attack_drone:OnTargetDamageResistedEvent(evt)
    if evt:GetOwner() ~= self.entity and evt:GetCreator() ~= self.entity then
        return
    end

    local target = evt:GetEntity()
    self.target_resisted_damage[ target ] = GetLogicTime() + self.target_resisted_timeout
end

function attack_drone:SetCurrentTarget( target )
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

function attack_drone:OnTargetHasChangedEvent(evt)
    if not self.target_finder or evt:GetTag() ~= self.target_finder.name then
        return
    end

    if not self.is_enabled then
        return
    end

    local target = evt:GetTarget()
    self:SetCurrentTarget(target)
end

function attack_drone:FindActionTarget()
    self:EnsureTargetFinder()

    return self.drone_target
end

function attack_drone:OnAttackExecute(state, dt)
    local attack_duration = state:GetDuration() - ( self.attack_start_timer or state:GetDuration())


    if self:IsTargetValid( self.drone_target ) and ( attack_duration < 1.0 or self.weapon_controller.ShootAtTarget( self, self.drone_target ) ) then
        UnitService:SetCurrentTarget(self.entity, "action", self.drone_target )

        self.attack_stop_timer = nil
        if self.attack_start_timer == nil then
            self.attack_start_timer = state:GetDuration()
        end
    elseif self.attack_start_timer then
        UnitService:SetCurrentTarget(self.entity, "action", self:GetDroneOwnerTarget() )
        self.attack_start_timer = nil;
        self.attack_stop_timer = state:GetDuration()
    end

    EntityService:LookAt( self.entity, self:GetDroneActionTarget(), true )

    if self.attack_stop_timer then
        local non_attack_duration = state:GetDuration() - ( self.attack_stop_timer or state:GetDuration())
        if non_attack_duration > 0.5 then
            self.weapon_controller.StopShooting( self )
        end

        if non_attack_duration > self.non_action_timeout then
            self:SetTargetActionFinished()
        end
    end
end

function attack_drone:OnRelease()
    if not self.target_finder then
        return
    end

    if EntityService:IsAlive(self.target_finder.entity) then
        UnitService:RemoveFindTargetRequest( self.target_finder.entity, self.target_finder.name );
    end
end

function attack_drone:EnsureTargetFinder()
    if not self.target_finder then
        local owner = self:GetDroneOwnerTarget()
        self:RegisterHandler(owner, "TargetHasChangedEvent", "OnTargetHasChangedEvent")

        self.target_finder = { name = "attack_drone##" .. tostring( self.entity ), entity = owner }

        if self.target_aggresive_only then
            UnitService:CreateCustomFindTargetRequest( owner, self.target_finder.name, self.search_radius, "hostility", "ground_unit", "AggressiveTargetFinder" );
        else
            UnitService:CreateFindTargetRequest( owner, self.target_finder.name, self.search_radius, "hostility", "ground_unit" );
        end
    end
end

function attack_drone:DefaultWeaponControllerShootAtTarget( target )
    WeaponService:RotateWeaponMuzzleToTarget( self.entity, self.drone_target )

    if self.is_landing or self.is_lifting then
        return true
    end

    local is_shooting = WeaponService:IsShooting( self.entity );
    if is_shooting and ( self.is_landing or self.is_lifting ) then
        WeaponService:StopShoot(self.entity);
        return true
    end

    if not is_shooting then
        WeaponService:StartShoot( self.entity );
    end

    return true;
end

function attack_drone:DefaultWeaponControllerStopShooting()
    WeaponService:StopShoot(self.entity);
end

function attack_drone:TurretWeaponControllerShootAtTarget( target )
end

function attack_drone:TurretWeaponControllerStopShooting()
end

return attack_drone;