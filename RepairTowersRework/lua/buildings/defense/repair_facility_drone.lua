require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/drone_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'repair_facility_drone' ( drone_spawner_building )

function repair_facility_drone:__init()
    drone_spawner_building.__init(self,self)
end

function repair_facility_drone:OnInit()
    drone_spawner_building.OnInit( self )
    
    self.energy_cost = self.data:GetFloatOrDefault("energy_cost", 20)

    self.nearby_drones = 0
    self.working_drones = 0

    self:CreateDronePoint()
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function repair_facility_drone:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateDronePoint()
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function repair_facility_drone:UpdateWorkingDrones(drone_enabled)
    if drone_enabled then
        self.working_drones = self.working_drones + 1

        if self.working_drones == 1 then
            BuildingService:AddConverterCostModifier( self.entity, self.energy_cost, "drones" )
        end
    else
        self.working_drones = self.working_drones - 1

        if self.working_drones == 0 then
            BuildingService:RemoveConverterCostModifier( self.entity, "drones" )
        end
    end
end

function repair_facility_drone:OnDroneLiftingStarted(drone)
    self:UpdateWorkingDrones(true)

    --QueueEvent( "FadeEntityInRequest", drone, 0.5 )
end

function repair_facility_drone:OnDroneLandingStarted(drone)
    self:UpdateWorkingDrones(false)

    --QueueEvent( "FadeEntityOutRequest", drone, 2.0 )
end

function repair_facility_drone:CreateDronePoint()

    if ( self.pointEntity == nil ) then

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = self.data:GetFloatOrDefault("drone_point_entity_x", transform.position.x)
        local newPositionZ = self.data:GetFloatOrDefault("drone_point_entity_z", transform.position.z)

        local team = EntityService:GetTeam( self.entity )
        self.pointEntity = EntityService:SpawnAndAttachEntity( "buildings/tower_drone_point", self.entity, team )

        ItemService:SetInvisible(self.pointEntity, true)

        self:SetDronePointPosition( newPositionX, newPositionZ )
    end

    EntityService:SetName( self.pointEntity, "drone_point_entity" )

    self.data:SetInt("drone_point_entity", self.pointEntity)
end

function repair_facility_drone:OnDronePointEvent(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName == "DronePointChangeEvent" ) then
        local newPositionX = eventDatabase:GetFloat("point_x")
        local newPositionZ = eventDatabase:GetFloat("point_z")

        self:SetDronePointPosition( newPositionX, newPositionZ )

    elseif ( eventName == "DronePointSelectedEvent" ) then

        local selected = ( eventDatabase:GetStringOrDefault("isBuildingSelected", "0") == "1" )

        self.dronePointSelected = selected

        self:UpdateDronePointSkinMaterial()
    end
end

function repair_facility_drone:OnActivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = true

    self:UpdateDronePointSkinMaterial()
end

function repair_facility_drone:OnDeactivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = false

    self:UpdateDronePointSkinMaterial()
end

function repair_facility_drone:SetDronePointPosition( newPositionX, newPositionZ )

    self.data:SetFloat("drone_point_entity_x", newPositionX)
    self.data:SetFloat("drone_point_entity_z", newPositionZ)

    local transform = EntityService:GetWorldTransform( self.entity )

    local newRelativePosition ={
        x = newPositionX - transform.position.x,
        y = 0,
        z = newPositionZ - transform.position.z
    }

    local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

    local pointX = MathRound(inverteRotatedPosition.x)
    local pointZ = MathRound(inverteRotatedPosition.z)

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

    self:RepositionLinkEntity()
end

function repair_facility_drone:UpdateDisplayRadiusVisibility( show, entity )

    self.display_radius_requesters = self.display_radius_requesters or {}

    if show then
        if self.display_radius_requesters[ entity ] then
            return
        end

        self.display_radius_requesters[ entity ] = true

        local count = 0
        for entityTemp,_ in pairs(self.display_radius_requesters) do
            if ( EntityService:IsAlive( entityTemp ) ) then
                count = count + 1
            end
        end

        if count == 1 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" );

            local component = reflection_helper( EntityService:CreateComponent(self.pointEntity,"DisplayRadiusComponent") )
            component.min_radius = self.display_radius_size.min;
            component.max_radius = self.display_radius_size.max;
            component.max_radius_blueprint = self.display_effect_blueprint;

            self.dronePointSelected = self.dronePointSelected or false

            if ( self.dronePointSelected ) then
                EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
            else
                EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
            end

            self:CreateLinkEntity()

            self:RepositionLinkEntity()
        end
    else
        self.display_radius_requesters[ entity ] = nil

        local count = 0

        for entityTemp,_ in pairs(self.display_radius_requesters) do
            if ( EntityService:IsAlive( entityTemp ) ) then
                count = count + 1
            end
        end
        
        if count == 0 then
            EntityService:RemoveComponent( self.pointEntity, "DisplayRadiusComponent" )
            EntityService:RemoveMaterial( self.pointEntity, "selected" )

            self:RemoveLinkEntity()
        end
    end
end

function repair_facility_drone:UpdateDronePointSkinMaterial()

    local count = 0
    for entityTemp,_ in pairs(self.display_radius_requesters) do
        if ( EntityService:IsAlive( entityTemp ) ) then
            count = count + 1
        end
    end

    self.dronePointSelected = self.dronePointSelected or false

    if count == 1 then
        if ( self.dronePointSelected ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
        end
    else
        EntityService:RemoveMaterial( self.pointEntity, "selected" )
    end
end

function repair_facility_drone:CreateLinkEntity()

    if ( self.linkEntity ~= nil ) then
        return
    end

    local team = EntityService:GetTeam( self.entity )
    self.linkEntity = EntityService:SpawnAndAttachEntity( "effects/drone_point_effects/drone_point_link", self.entity, team)

    ItemService:SetInvisible(self.linkEntity, true)
end

function repair_facility_drone:RemoveLinkEntity()

    if ( self.linkEntity == nil ) then
        return
    end

    EntityService:RemoveEntity(self.linkEntity)
    self.linkEntity = nil
end

function repair_facility_drone:RepositionLinkEntity()

    if ( self.linkEntity == nil or self.pointEntity == nil ) then
        return
    end

    local selfPosition = EntityService:GetPosition(self.entity)
    local pointPosition = EntityService:GetPosition(self.pointEntity)

    local direction = VectorMulByNumber( Normalize( VectorSub( pointPosition, selfPosition ) ), 2.0 )
    selfPosition = VectorAdd(selfPosition, direction)

    local lightningComponent = reflection_helper(EntityService:GetComponent(self.linkEntity, "LightningComponent"))

    local container = rawget(lightningComponent.lighning_vec, "__ptr");

    local item = container:GetItem(0)
    if ( item == nil ) then 
        item = container:CreateItem()
    end

    local instance =  reflection_helper(item)

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    local sizePoint = EntityService:GetBoundsSize( self.pointEntity )

    instance.start_point.x = selfPosition.x
    instance.start_point.y = selfPosition.y + sizeSelf.y + 2
    instance.start_point.z = selfPosition.z

    instance.end_point.x = pointPosition.x
    instance.end_point.y = pointPosition.y + sizePoint.y + 2
    instance.end_point.z = pointPosition.z
end

function repair_facility_drone:TrasferingInfoToUpgrade(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == false) then
        return
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindGridOwnersByBox( min, max )

    for entity in Iter( entities ) do

        if ( entity == eventEntity ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper(buildingDesc)
        if ( buildingDescRef.upgrade ~= selfBlueprintName ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= selfLowName ) then
            goto continue
        end

        local baseDatabase = EntityService:GetDatabase( entity )

        local transform = EntityService:GetWorldTransform( self.entity )

        local newPositionX = baseDatabase:GetFloatOrDefault("drone_point_entity_x", transform.position.x)
        local newPositionZ = baseDatabase:GetFloatOrDefault("drone_point_entity_z", transform.position.z)

        self:SetDronePointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function repair_facility_drone:OnRelease()

    self:RemoveLinkEntity()

    if ( self.pointEntity ~= nil ) then

        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease(self)
    end
end

return repair_facility_drone
