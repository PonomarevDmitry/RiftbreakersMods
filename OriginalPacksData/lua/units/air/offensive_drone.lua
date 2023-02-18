local base_drone = require("lua/units/air/base_drone.lua")
class 'offensive_drone' ( base_drone )

function offensive_drone:__init()
	base_drone.__init(self,self)
end

function offensive_drone:FillInitialParams()
    if self.data:HasFloat("drone_search_radius") then
        self.search_radius = self.data:GetFloat("drone_search_radius")
    else
        self.search_radius = self.data:GetFloat("search_radius")
    end
    self.search_type = self.data:GetStringOrDefault("search_type", "");

    UnitService:RemoveFindTargetRequest( self.entity, "action" );
    UnitService:CreateFindTargetRequest( self.entity, "action", self.search_radius, "hostility", self.search_type );

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "attack", { enter="OnAttackEnter", execute="OnAttackExecute", exit="OnAttackExit" } );
end

function offensive_drone:OnInit()
    self:FillInitialParams();
end

function offensive_drone:OnLoad()
    self:FillInitialParams();

    base_drone.OnLoad( self )
end

function offensive_drone:OnDroneTargetAction( target )
    self:SetTargetActionFinished();
end

function offensive_drone:OnAttackEnter()
    self:ChangeState("attack")
end

function offensive_drone:OnAttackExecute()
    local target = self:GetDroneActionTarget();
    if not EntityService:IsAlive( target ) then state:Exit() end
end

function offensive_drone:OnAttackExit()
    WeaponService:StopShoot(self.entity);
    self:SetTargetActionFinished();
end

return offensive_drone;