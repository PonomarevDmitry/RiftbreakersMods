require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

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

    LogService:Log("OnInit self.entity " .. tostring(self.entity))

    self:CreateDronePoint("OnInit")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointChange" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
end

function repair_facility_drone:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    LogService:Log("OnLoad self.entity " .. tostring(self.entity))

    self:CreateDronePoint("OnLoad")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointChange" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
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

function repair_facility_drone:CreateDronePoint(text)

    if ( self.pointEntity == nil ) then

        local pointX = self.data:GetFloatOrDefault("drone_point_entity_x", 0)
        local pointZ = self.data:GetFloatOrDefault("drone_point_entity_z", 0)

        LogService:Log(text .. " CreateDronePoint pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

        local team = EntityService:GetTeam( self.entity )

        self.pointEntity = EntityService:SpawnAndAttachEntity( "buildings/tower_drone_point", self.entity, team )
        EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

        LogService:Log(text .. " CreateDronePoint drone_point_entity " .. tostring(self.pointEntity))
    end

    EntityService:SetName( self.pointEntity, "drone_point_entity" )

    self.data:SetInt("drone_point_entity", self.pointEntity)
end

function repair_facility_drone:OnDronePointChange(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName ~= "DronePointChangeEvent" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local pointX = eventDatabase:GetFloat("point_x") - transform.position.x
    local pointZ = eventDatabase:GetFloat("point_z") - transform.position.z

    self.data:SetFloat("drone_point_entity_x", pointX)
    self.data:SetFloat("drone_point_entity_z", pointZ)

    LogService:Log("OnDronePointChange pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

    local transform = EntityService:GetWorldTransform( self.entity )

    self:CreateDronePoint("OnDronePointChange")

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )
end

function repair_facility_drone:UpdateDisplayRadiusVisibility( show, entity )

    self.display_radius_requesters = self.display_radius_requesters or {}

    self:CreateDronePoint("UpdateDisplayRadiusVisibility")

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

            EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
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
        end
    end
end

function repair_facility_drone:TrasferingInfoToUpgrade(evt)

    LogService:Log("TrasferingInfoToUpgrade self.entity " .. tostring(self.entity))

    local eventEntity = evt:GetEntity()

    LogService:Log("TrasferingInfoToUpgrade eventEntity " .. tostring(eventEntity))

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

        LogService:Log("TrasferingInfoToUpgrade entity " .. tostring(entity))

        local baseDatabase = EntityService:GetDatabase( entity )

        local pointX = baseDatabase:GetFloatOrDefault("drone_point_entity_x", 0)
        local pointZ = baseDatabase:GetFloatOrDefault("drone_point_entity_z", 0)

        LogService:Log("TrasferingInfoToUpgrade pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

        self.data:SetFloat("drone_point_entity_x", pointX)
        self.data:SetFloat("drone_point_entity_z", pointZ)

        self:CreateDronePoint("TrasferingInfoToUpgrade")

        EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

        ::continue::
    end
end

return repair_facility_drone
