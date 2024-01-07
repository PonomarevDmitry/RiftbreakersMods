require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'tower_drone_attack' ( drone_spawner_building )

function tower_drone_attack:__init()
    drone_spawner_building.__init(self,self)
end

function tower_drone_attack:OnInit()

    if ( drone_spawner_building.OnInit ) then
        drone_spawner_building.OnInit(self)
    end

    self:CreateDronePoint("OnLoad")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointChange" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
end

function tower_drone_attack:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateDronePoint("OnLoad")
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointChange" )
    self:RegisterHandler( self.entity, "BuildingStartEvent", "TrasferingInfoToUpgrade" )
end

function tower_drone_attack:CreateDronePoint(text)

    if ( self.pointEntity == nil ) then

        local pointX = self.data:GetFloatOrDefault("drone_point_entity_x", 0)
        local pointZ = self.data:GetFloatOrDefault("drone_point_entity_z", 0)

        LogService:Log(text .. " CreateDronePoint pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

        local team = EntityService:GetTeam( self.entity )

        self.pointEntity = EntityService:SpawnAndAttachEntity( "misc/area_center_point", self.entity, team )
        EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

        LogService:Log(text .. " CreateDronePoint drone_point_entity " .. tostring(self.pointEntity))
    end

    EntityService:SetName( self.pointEntity, "drone_point_entity" )

    self.data:SetInt("drone_point_entity", self.pointEntity)
end

function tower_drone_attack:OnDronePointChange(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName ~= "AreaCenterPointChangeEvent" ) then
        return
    end

    local transform = EntityService:GetWorldTransform( self.entity )

    local newPositionX = eventDatabase:GetFloat("point_x")
    local newPositionZ = eventDatabase:GetFloat("point_z")

    local newRelativePosition ={
        x = newPositionX - transform.position.x,
        y = 0,
        z = newPositionZ - transform.position.z
    }

    local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

    local pointX = SnapValue(inverteRotatedPosition.x, 1)
    local pointZ = SnapValue(inverteRotatedPosition.z, 1)

    LogService:Log("OnDronePointChange inverteRotatedPosition.x " .. tostring(inverteRotatedPosition.x) .. " inverteRotatedPosition.y " .. tostring(inverteRotatedPosition.y) .. " inverteRotatedPosition.z " .. tostring(inverteRotatedPosition.z) .. " inverteRotatedPosition.w " .. tostring(inverteRotatedPosition.w))

    self.data:SetFloat("drone_point_entity_x", pointX)
    self.data:SetFloat("drone_point_entity_z", pointZ)

    LogService:Log("OnDronePointChange pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

    self:CreateDronePoint("OnDronePointChange")

    EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )
end

function tower_drone_attack:UpdateDisplayRadiusVisibility( show, entity )

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

function tower_drone_attack:TrasferingInfoToUpgrade(evt)

    LogService:Log("OnBuildingStartEvent self.entity " .. tostring(self.entity))

    local eventEntity = evt:GetEntity()

    LogService:Log("OnBuildingStartEvent eventEntity " .. tostring(eventEntity))

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

        LogService:Log("OnBuildingStartEvent entity " .. tostring(entity))

        local baseDatabase = EntityService:GetDatabase( entity )

        local pointX = baseDatabase:GetFloatOrDefault("drone_point_entity_x", 0)
        local pointZ = baseDatabase:GetFloatOrDefault("drone_point_entity_z", 0)

        LogService:Log("OnBuildingStartEvent pointX " .. tostring(pointX) .. " pointZ " .. tostring(pointZ))

        self.data:SetFloat("drone_point_entity_x", pointX)
        self.data:SetFloat("drone_point_entity_z", pointZ)

        self:CreateDronePoint("OnBuildingStartEvent")

        EntityService:SetPosition( self.pointEntity, pointX, 0, pointZ )

        ::continue::
    end
end

function tower_drone_attack:OnRelease()

    if ( self.pointEntity ~= nil ) then

        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease(self)
    end
end

return tower_drone_attack
