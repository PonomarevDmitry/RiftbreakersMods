require("lua/utils/string_utils.lua")

local base_drone = require("lua/units/air/base_drone.lua")
class 'mine_layer_drone' ( base_drone )

function mine_layer_drone:__init()
    base_drone.__init(self,self)
end

function mine_layer_drone:FillInitialParams()
    self.plant_radius = self.data:GetFloatOrDefault( "drone_search_radius", self.data:GetFloat("plant_radius") );
    self.plant_marker = self.data:GetString("plant_marker");
    self.plant_effect = self.data:GetString("plant_effect");
    self.target_found = INVALID_ID;
    self.team = EntityService:GetTeam( self.entity );
end

function mine_layer_drone:OnInit()
    self:FillInitialParams();

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState("find", { enter="OnFindEnter", exit="OnFindExit", execute="OnFindExecute", interval=2.0 } );
    self.fsm:AddState("plant", { enter="OnPlantEnter", execute="OnPlantExecute", exit="OnPlantExit", interval=0.5 } );

    self:RegisterHandler(self.entity, "AttachEffectGroupRequest", "OnAttachEffectGroupRequest")

    self.is_visible = false
end

function mine_layer_drone:OnLoad()
    self:FillInitialParams();

    if ( self.fsm and self.fsm:GetState("find") == nil ) then
        self.fsm:AddState("find", { enter="OnFindEnter", exit="OnFindExit", execute="OnFindExecute", interval=2.0 } );
    end

    base_drone.OnLoad( self )
end

function mine_layer_drone:OnAttachEffectGroupRequest(evt)
    if not self.is_visible then
        QueueEvent( "RemoveEffectsByGroupRequest", self.entity, "fly", 0.0 )
    end
end

function mine_layer_drone:OnDroneLifting()
    QueueEvent( "FadeEntityInRequest", self.entity, 0.2 )
end

function mine_layer_drone:FindActionTarget()
    local owner = self:GetDroneOwnerTarget();
    if not HealthService:IsAlive( owner ) then
        return INVALID_ID
    end

    if not EntityService:IsAlive( self.target_found ) then
        self.target_found = INVALID_ID

        if self.fsm:GetCurrentState() ~= "find" then
            self.fsm:ChangeState("find")
        end

        return INVALID_ID;
    else
        self.fsm:Deactivate();
    end

    AnimationService:ResetPose(self.entity )
    AnimationService:StartAnim(self.entity, "opening", false, 0.5 )

    self.is_visible = true
    return self.target_found;
end

function mine_layer_drone:CreateFindRequest()
    local owner = self:GetDroneFindCenterPoint();
    if owner ~= INVALID_ID then
        self.finder.owner = owner
        self.finder.event_name = tostring( self.entity )

        FindService:CreateFindEmptySpotRequest( self.finder.owner, self.finder.event_name, self.plant_radius );
    end
end

function mine_layer_drone:OnTargetFoundEvent(evt)
    if not self.finder then
        return
    end

    if evt:GetTag() ~= self.finder.event_name then
        return
    end
    
    local position = evt:GetTarget()
    if FindService:IsSpotEmpty( position ) then
        local marker = EntityService:SpawnEntity(self.plant_marker, position, self.team );
        EntityService:Rotate(marker, 0.0, 1.0, 0.0, RandFloat(0.0, 360.0));
        EntityService:CreateOrSetLifetime( marker, 60.0, "normal" )

        self.fsm:Deactivate();

        self.target_found = marker
    else
        self.create_finder = true
    end
end

function mine_layer_drone:OnTargetNotFoundEvent()
    self.create_finder = true
end

function mine_layer_drone:OnFindEnter(state)
    self.finder = {}
    self.finder.owner = self:GetDroneFindCenterPoint()

    if self.finder.owner ~= INVALID_ID then
        self:RegisterHandler( self.finder.owner, "TargetFoundEvent", "OnTargetFoundEvent" )
        self:RegisterHandler( self.finder.owner, "TargetNotFoundEvent", "OnTargetNotFoundEvent" )

        self:CreateFindRequest();
    else
        state:Exit()
    end
end

function mine_layer_drone:OnFindExit()
    if self.finder then
        self:UnregisterHandler( self.finder.owner, "TargetFoundEvent", "OnTargetFoundEvent" )
        self:UnregisterHandler( self.finder.owner, "TargetNotFoundEvent", "OnTargetNotFoundEvent" )
    end

    self.finder = nil
end

function mine_layer_drone:OnFindExecute()
    if self.create_finder then
        self:CreateFindRequest();
    end
end

function mine_layer_drone:OnDroneTargetAction( target )
    self.fsm:ChangeState( "plant" )
    return false;
end

function mine_layer_drone:OnPlantEnter(state)
    EffectService:AttachEffects(self.entity, "work");

    EffectService:SpawnEffect(self.entity, self.plant_effect );
    AnimationService:StartAnim(self.entity, "landing", false )
end

function mine_layer_drone:OnPlantExecute(state)
    if not AnimationService:IsAnimActive(self.entity, "landing" ) then
        state:Exit()
    end
end

function mine_layer_drone:OnPlantExit()
    EffectService:DestroyEffectsByGroup(self.entity, "work");

    local target = self:GetDroneActionTarget();
    if EntityService:IsAlive(target) then 
        EntityService:RemovePropsInEntityBounds( target )

        local plant_blueprint = self.data:GetStringOrDefault("plant_blueprint", "");

        local entity = EntityService:SpawnEntity(plant_blueprint, target, EntityService:GetTeam(self.entity) )
        EntityService:SpawnAndAttachEntity(self.plant_marker, entity )

        self.is_visible = false
        QueueEvent( "FadeEntityOutRequest", self.entity, 0.1 )
        EffectService:DestroyEffectsByGroup(self.entity, "fly");

        EntityService:RemoveEntity( target )
        self.target_found = INVALID_ID
    end

    self:SetTargetActionFinished();
end

function mine_layer_drone:GetDroneFindCenterPoint()

    local owner = self:GetDroneOwnerTarget();

    local database = EntityService:GetDatabase( owner )

    if ( database and database:HasInt("drone_point_entity") and EntityService:HasComponent( owner, "BuildingComponent" ) ) then

        local pointEntity = database:GetIntOrDefault("drone_point_entity", INVALID_ID) or INVALID_ID

        if ( pointEntity ~= nil and pointEntity ~= INVALID_ID and EntityService:IsAlive( pointEntity ) ) then

            owner = pointEntity
        end
    end

    return owner
end

function mine_layer_drone:OnOwnerDistanceCheckExecute()
    local owner = self:GetDroneOwnerTarget()
    if not EntityService:IsAlive(owner) then
        return
    end

    local pointEntity = self:GetDroneFindCenterPoint()

    local distance, closestPosition = self:GetDistanceToLineSegment(owner, pointEntity)

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
    end
end

function mine_layer_drone:GetDistanceToLineSegment(owner, pointEntity)

    local ownerPosition = EntityService:GetPosition(owner)
    local pointEntityPosition = EntityService:GetPosition(pointEntity)

    if ( owner == pointEntity ) then

        return EntityService:GetDistance2DBetween(self.entity, owner), ownerPosition
    end

    local abx = pointEntityPosition.x - ownerPosition.x
    local abz = pointEntityPosition.z - ownerPosition.z

    if ( abx == 0 and abz == 0 ) then

        return EntityService:GetDistance2DBetween(self.entity, owner), ownerPosition
    end

    local entityPosition = EntityService:GetPosition(self.entity)

    local dacab = (entityPosition.x - ownerPosition.x) * abx + (entityPosition.z - ownerPosition.z) * abz
    local dab = abx * abx + abz * abz

    local coef = dacab / dab

    if ( 0 <= coef and coef <= 1) then

        local projectionX = ownerPosition.x + abx * coef
        local projectionZ = ownerPosition.z + abz * coef

        local result = math.sqrt( (entityPosition.x - projectionX) * (entityPosition.x - projectionX) + (entityPosition.z - projectionZ) * (entityPosition.z - projectionZ) )

        local newPosition = {}
        newPosition.x = projectionX
        newPosition.y = 0
        newPosition.z = projectionZ

        return result, newPosition
    end

    local distance1 = EntityService:GetDistance2DBetween(self.entity, owner)
    local distance2 = EntityService:GetDistance2DBetween(self.entity, pointEntity)

    if ( distance1 < distance2) then
        return distance1, ownerPosition
    else
        return distance2, pointEntityPosition
    end
end

return mine_layer_drone;