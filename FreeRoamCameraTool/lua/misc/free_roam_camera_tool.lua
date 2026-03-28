require("lua/utils/numeric_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/find_utils.lua")
require("lua/utils/reflection.lua")

class 'free_roam_camera_tool' ( LuaEntityObject )

function free_roam_camera_tool:__init()
    LuaEntityObject.__init(self,self)
end

function free_roam_camera_tool:init()
    self:InitializeValues()
end

function free_roam_camera_tool:InitializeValues()

    self.previousSelected = {}
    self.selectedEntities = {}

    self.selector = EntityService:GetParent( self.entity )

    self:RegisterHandler( self.selector, "ActivateSelectorRequest", "OnActivateSelectorRequest" )
    self:RegisterHandler( self.selector, "DeactivateSelectorRequest", "OnDeactivateSelectorRequest" )
    self:RegisterHandler( self.selector, "RotateSelectorRequest", "OnRotateSelectorRequest" )

    local playerReferenceComponent = reflection_helper( EntityService:GetComponent(self.selector, "PlayerReferenceComponent") )
    self.playerId = playerReferenceComponent.player_id

    self.action = self.data:GetStringOrDefault( "action", "" )

    local orientation = { x=0, y=0, z=0, w=1 }
    EntityService:SetOrientation( self.entity, orientation )

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_free_roam_camera_tool", self.entity)

    self.cameraEnt = CameraService:GetLeadingPlayerCamera()

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    self.yaw_angle = followCameraComponent.yaw_angle.radian

    --LogService:Log("self.yaw_angle " .. tostring(self.yaw_angle))

    self.oldTargetEnt = CameraService:GetFollowTarget( self.cameraEnt )

    self.currentAngle = 0

    self.stepAngle = 5
    --self.stepAngle = 1

    local boundsSize = EntityService:GetBoundsSize( self.selector )
    self.boundsSize = VectorMulByNumber( boundsSize, 0.5 )

    self.stateMachine = self:CreateStateMachine()
    self.stateMachine:AddState( "working", { execute="OnWorkExecute" } )
    self.stateMachine:ChangeState("working")
    
    self.clickStateMachine = self:CreateStateMachine()
    self.clickStateMachine:AddState( "delay", { execute="OnClickDelayExecute", interval = 0.5 } )
    self.clickStateMachine:AddState( "working", { execute="OnClickWorkExecute", interval = 0.1 } )
end

function free_roam_camera_tool:OnWorkExecute()
    
    local selectorComponent = EntityService:GetComponent(self.selector, "BuildingSelectorComponent") 

    local previousSelection = self.selectedEntities

    self.selectedEntities =  self:FindEntitiesToSelect( reflection_helper(selectorComponent) )

    for ent in Iter( previousSelection ) do 
        if ( IndexOf( self.selectedEntities, ent ) == nil ) then
            self:RemovedFromSelection( ent )
        end
    end
    
    for ent in Iter( self.selectedEntities ) do 
        if ( IndexOf( previousSelection, ent ) == nil ) then
            self:AddedToSelection( ent )
        end
    end
end

function free_roam_camera_tool:FindEntitiesToSelect( selectorComponent)

    self.position = selectorComponent.position

    local min = VectorSub( self.position, self.boundsSize )
    local max = VectorAdd( self.position, self.boundsSize )

    local possibleSelectedEnts = {}

    local scaleSelector = 0
    local stepScaleSelector = 0.5
    local maxScaleSelector = 2

    while (#possibleSelectedEnts == 0 and scaleSelector < maxScaleSelector) do

        local predicate = {

            signature="SelectableComponent",

            filter = function(entity)
                local pos = EntityService:GetPosition(entity )
                local distance = Distance( self.position, pos )

                local bounds = EntityService:GetBoundsSize( entity )

                if ( EntityService:GetGroup(entity ) == "##ruins##" ) then
                    local size = Length(bounds)
                    return distance <= size
                end

                if( EntityService:HasComponent( entity, "BuildingComponent" ) == true ) then
                    return false
                end

                local maxSize = math.max(bounds.x, bounds.z)

                return distance <= maxSize
            end
        };

        scaleSelector = scaleSelector + stepScaleSelector

        min = VectorSub(self.position, VectorMulByNumber( self.boundsSize, scaleSelector) )
        max = VectorAdd(self.position, VectorMulByNumber( self.boundsSize, scaleSelector) )

        possibleSelectedEnts = FindService:FindEntitiesByPredicateInBox( min, max, predicate );
    end

    local sorter = function( t, lhs, rhs )
        local p1 = EntityService:GetPosition(lhs )
        local p2 = EntityService:GetPosition(rhs )
        local d1 = Distance( self.position, p1 )
        local d2 = Distance( self.position, p2 )
        return d1 < d2
    end

    table.sort(possibleSelectedEnts, function(a,b) return sorter(possibleSelectedEnts, a, b) end)

    local selectedEntities = {}

    for testEntity in Iter(possibleSelectedEnts ) do

        local entity = EntityService:GetAncestorWithSignature( testEntity, "SelectableComponent" )
        if ( entity == INVALID_ID ) then goto continue end

        local buildingsComponent = EntityService:GetComponent( entity, "BuildingComponent" )

        if ( buildingComponent ~= nil ) then
            local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
            if ( mode <= 2 ) then goto continue end
        end

        Insert(selectedEntities, entity )

        ::continue::
    end

    return selectedEntities
end

function free_roam_camera_tool:AddedToSelection( entity )

    QueueEvent( "SelectEntityRequest", entity )
end

function free_roam_camera_tool:RemovedFromSelection( entity )

    QueueEvent( "DeselectEntityRequest", entity )
end

function free_roam_camera_tool:OnClickDelayExecute()

    self.clickStateMachine:ChangeState("working")
end

function free_roam_camera_tool:OnClickWorkExecute()

    if ( self.activated )  then
        
        self:ChangeCameraLocation()
    end
end

function free_roam_camera_tool:OnActivateSelectorRequest()

    self.activated = true

    self:ChangeCameraLocation()

    self.clickStateMachine:ChangeState("delay")
end

function free_roam_camera_tool:ChangeCameraLocation()

    local position = EntityService:GetPosition( self.entity )

    if ( self.tempEntity == nil ) then
        self.tempEntity = EntityService:SpawnEntity( position )
    end

    EntityService:SetPosition( self.tempEntity, position )

    CameraService:SetFollowTarget( self.cameraEnt, self.tempEntity )
end

function free_roam_camera_tool:OnDeactivateSelectorRequest()

    self.activated = false

    self.clickStateMachine:Deactivate()
end

function free_roam_camera_tool:OnRotateSelectorRequest( evt )

    local degree = evt:GetDegree()



    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end



    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    self.currentAngle = self.currentAngle + change * self.stepAngle

    while (self.currentAngle >= 360) do
        self.currentAngle = self.currentAngle - 360
    end

    while (self.currentAngle < 0) do
        self.currentAngle = self.currentAngle + 360
    end

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )

    local additionalAngleRadian = math.pi * self.currentAngle / 180

    followCameraComponent.yaw_angle.radian = self.yaw_angle + additionalAngleRadian

    --LogService:Log("self.currentAngle " .. tostring(self.currentAngle) .. " followCameraComponent.yaw_angle.radian " .. tostring(followCameraComponent.yaw_angle.radian))
end

function free_roam_camera_tool:OnRelease()

    for entity in Iter( self.selectedEntities ) do
        self:RemovedFromSelection( entity )
    end

    local cameraOwner = EntityService:GetParent(self.cameraEnt)

    local followCameraComponent = reflection_helper( EntityService:GetComponent(cameraOwner, "FollowCameraControllerComponent") )
    followCameraComponent.yaw_angle.radian = self.yaw_angle

    CameraService:SetFollowTarget( self.cameraEnt, self.oldTargetEnt )

    if ( self.childEntity ~= nil ) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.tempEntity ~= nil ) then
        EntityService:RemoveEntity(self.tempEntity)
        self.tempEntity = nil
    end
end

return free_roam_camera_tool
