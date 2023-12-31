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

    self.non_action_timeout = RandFloat(2.5,5.0)

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

    self.allow_target = 0.0
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

    LogService:Log("IsTargetValid " )

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

    LogService:Log("SetCurrentTarget " )

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

function attack_drone:UpdateInitialState()

    LogService:Log("UpdateInitialState " )

    local owner = self:GetDroneOwnerTarget();

    QueueEvent( "EnableDroneRequest", self.entity )

    self.is_lifting = false
    self.is_landing = false
    self.has_speed_penalty = self.has_speed_penalty or false
end

function attack_drone:SetEnabled( enabled )

    LogService:Log("SetEnabled " )

    self.is_enabled = true

    if self.OnDroneEnabled then
        self:OnDroneEnabled()
    end
    UnitService:SetStateMachineParam(self.entity, "is_enabled", 1)
end

function attack_drone:OnOwnerDistanceCheckExecute()

    LogService:Log("OnOwnerDistanceCheckExecute " )

    local owner = self:GetDroneOwnerTarget()

    --if not EntityService:IsAlive(owner) then
    --    return
    --end

    --local distance = EntityService:GetDistance2DBetween(self.entity, owner)
    --if self.search_radius and distance > self.search_radius * 2.0 and EntityService:GetComponent(self.entity, "IsVisibleComponent") == nil then
    --
    --    if self.is_enabled then
    --        QueueEvent( "DisableDroneRequest", self.entity )
    --        QueueEvent( "EnableDroneRequest", self.entity )
    --    end
    --
    --    local target_position = EntityService:GetPosition(owner)
    --    target_position.y = EntityService:GetPositionY(self.entity)
    --
    --    EntityService:Teleport(self.entity, target_position)
    --    QueueEvent( "FadeEntityInRequest", self.entity, 0.3 )
    --end

    local action_target = self:GetDroneActionTarget()
    if action_target ~= INVALID_ID and not EntityService:IsAlive(action_target) then
        self:SetTargetActionFinished()
    end
end

function attack_drone:OnTargetHasChangedEvent(evt)
    if not self.target_finder or evt:GetTag() ~= self.target_finder.name then
        return
    end

    --if not self.is_enabled then
    --    return
    --end

    LogService:Log("OnTargetHasChangedEvent " )

    local target = evt:GetTarget()

    self:SetCurrentTarget(target)
end

function attack_drone:FindActionTarget()

    LogService:Log("FindActionTarget " )

    self:EnsureTargetFinder()

    return self.drone_target
end

function attack_drone:OnAttackExecute(state, dt)
    local attack_duration = state:GetDuration() - ( self.attack_start_timer or state:GetDuration())

    if self.allow_target > 0 and not self:IsTargetValid(self.drone_target) then
        self.allow_target = math.max(0.0, self.allow_target - dt); 
        local new_target = self:FindActionTarget(); -- Function return the new target
        if new_target ~= INVALID_ID then
            self.drone_target = new_target
        end
    end

    local owner = self:GetDroneOwnerTarget()

    if self:IsTargetValid( self.drone_target ) and ( attack_duration < 0.1 or self.weapon_controller.ShootAtTarget( self, self.drone_target ) ) then
        UnitService:SetCurrentTarget(self.entity, "action", self.drone_target )

        self.attack_stop_timer = nil
        if self.attack_start_timer == nil then
            self.attack_start_timer = state:GetDuration()
        end
        self.allow_target = 1.0
    elseif self.allow_target == 0 and self.attack_start_timer ~= nil then
        self.weapon_controller.StopShooting( self )
        UnitService:SetCurrentTarget(self.entity, "action", owner )
        self.attack_start_timer = nil;
        self.attack_stop_timer = state:GetDuration()
    end

    EntityService:LookAt( self.entity, self:GetDroneActionTarget(), true )

    if self.attack_stop_timer then
        local non_attack_duration = state:GetDuration() - ( self.attack_stop_timer or state:GetDuration())
        if non_attack_duration > self.non_action_timeout then
            self:SetTargetActionFinished()
            self.attack_stop_timer = nil
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

    local owner = self:GetDroneOwnerTarget()

    local database = EntityService:GetDatabase( owner )

    local pointEntity = database:GetInt("drone_point_entity")

    LogService:Log("EnsureTargetFinder pointEntity " .. tostring(pointEntity))

    if not self.target_finder then

        self:RegisterHandler(pointEntity, "TargetHasChangedEvent", "OnTargetHasChangedEvent")

        self.target_finder = { name = "attack_drone##" .. tostring( self.entity ), entity = pointEntity }

        if self.target_aggresive_only then
            UnitService:CreateCustomFindTargetRequest( pointEntity, self.target_finder.name, self.search_radius, "hostility", "ground_unit", "AggressiveTargetFinder" );
        else
            UnitService:CreateFindTargetRequest( pointEntity, self.target_finder.name, self.search_radius, "hostility", "ground_unit" );
        end
    end
end

function attack_drone:DefaultWeaponControllerShootAtTarget( target )

    LogService:Log("DefaultWeaponControllerShootAtTarget " )

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

    LogService:Log("DefaultWeaponControllerStopShooting " )

    WeaponService:StopShoot(self.entity);
end

function attack_drone:TurretWeaponControllerShootAtTarget( target )
end

function attack_drone:TurretWeaponControllerStopShooting()
end

return attack_drone;