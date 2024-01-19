require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

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

    self:CreateCenterPoint()
    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function repair_facility_drone:OnLoad()

    if ( drone_spawner_building.OnLoad ) then
        drone_spawner_building.OnLoad(self)
    end

    self:CreateCenterPoint()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent" )

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

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

-- #region Drone Point

function repair_facility_drone:CreateCenterPoint()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local pointEntityBlueprintName = "misc/area_center_point"

    if ( self.pointEntity ~= nil and not EntityService:IsAlive(self.pointEntity) ) then
        self.pointEntity = nil
    end

    if ( self.pointEntity ~= nil ) then

        local pointEntityParent = EntityService:GetParent( self.pointEntity )

        if ( pointEntityParent == nil or pointEntityParent == INVALID_ID or pointEntityParent ~= self.entity ) then
            self.pointEntity = nil
        end
    end

    if ( self.pointEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == pointEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.pointEntity = child
                ItemService:SetInvisible(self.pointEntity, true)

                goto continue
            end
        end

        ::continue::
    end

    if ( self.pointEntity == nil ) then

        local newPositionX = 0
        local newPositionZ = 0

        if ( self.data:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = self.data:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

        local team = EntityService:GetTeam( self.entity )
        self.pointEntity = EntityService:SpawnAndAttachEntity( pointEntityBlueprintName, self.entity, team )

        ItemService:SetInvisible(self.pointEntity, true)

        self:SetCenterPointPosition( newPositionX, newPositionZ )
    end

    if ( self.pointEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == pointEntityBlueprintName and child ~= self.pointEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end

    EntityService:SetName( self.pointEntity, "center_point_entity" )

    self.data:SetInt("center_point_entity", self.pointEntity)
end

function repair_facility_drone:OnDronePointEvent(evt)

    local eventName = evt:GetEvent()
    local eventDatabase = evt:GetDatabase()
    local eventEntity = evt:GetEntity()

    if ( eventEntity ~= self.entity ) then
        return
    end

    if ( eventName == "AreaCenterPointChangeEvent" ) then

        local selfPosition = EntityService:GetPosition( self.entity )

        local newPositionX = eventDatabase:GetFloat("point_x") - selfPosition.x
        local newPositionZ = eventDatabase:GetFloat("point_z") - selfPosition.z

        self:SetCenterPointPosition( newPositionX, newPositionZ )

    elseif ( eventName == "AreaCenterPointSelectedEvent" ) then

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

function repair_facility_drone:SetCenterPointPosition( newPositionX, newPositionZ )

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local newRelativePosition ={
        x = newPositionX,
        y = 0,
        z = newPositionZ
    }

    self.data:SetVector(selfLowName .. "_center_point_vector", newRelativePosition)

    local transform = EntityService:GetWorldTransform( self.entity )

    local inverteRotatedPosition = QuatMulVec3( QuatConj(transform.orientation), newRelativePosition )

    local pointX = SnapValue(inverteRotatedPosition.x, 1)
    local pointZ = SnapValue(inverteRotatedPosition.z, 1)

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

            self:SetPointEntitySelectedSkin()

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

function repair_facility_drone:SetPointEntitySelectedSkin()

    self.dronePointSelected = self.dronePointSelected or false

    local isSkinned = EntityService:IsSkinned(self.pointEntity)

    if ( self.dronePointSelected ) then
        if ( isSkinned ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_pass", "selected" )
        end
    else
        if ( isSkinned ) then
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_skinned_blue", "selected" )
        else
            EntityService:SetMaterial( self.pointEntity, "selector/hologram_blue", "selected" )
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

    if count > 0 then
        self:SetPointEntitySelectedSkin()
    else
        EntityService:RemoveMaterial( self.pointEntity, "selected" )
    end

    self:RepositionLinkEntity()
end

function repair_facility_drone:CreateLinkEntity()

    local linkEntityBlueprintName = "effects/area_center_point_effects/area_center_point_link"

    if ( self.linkEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName ) then

                self.linkEntity = child
                ItemService:SetInvisible(self.linkEntity, true)

                goto continue
            end
        end

        ::continue::
    end

    if ( self.linkEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.linkEntity = EntityService:SpawnAndAttachEntity( linkEntityBlueprintName, self.entity, team)
        ItemService:SetInvisible(self.linkEntity, true)
    end

    if ( self.linkEntity ~= nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName and child ~= self.linkEntity ) then
                EntityService:RemoveEntity( child )
            end
        end
    end
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

    local lightningComponentRef = reflection_helper(EntityService:GetComponent(self.linkEntity, "LightningComponent"))

    local container = rawget(lightningComponentRef.lighning_vec, "__ptr");

    local item = container:GetItem(0)
    if ( item == nil ) then 
        item = container:CreateItem()
    end

    local instance =  reflection_helper(item)

    local sizeSelf = EntityService:GetBoundsSize( self.entity )
    local sizePoint = EntityService:GetBoundsSize( self.pointEntity )

    instance.start_point.x = selfPosition.x
    instance.start_point.y = selfPosition.y + sizeSelf.y
    instance.start_point.z = selfPosition.z

    instance.end_point.x = pointPosition.x
    instance.end_point.y = pointPosition.y + sizePoint.y + 2
    instance.end_point.z = pointPosition.z

    self.dronePointSelected = self.dronePointSelected or false

    if ( self.dronePointSelected ) then
        lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link_selected"
    else
        lightningComponentRef.material = "effects/area_center_point_effects/area_center_point_link"
    end
end

function repair_facility_drone:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == true) then

        self:GettingInfoFromBaseToUpgrade(eventEntity)
    else
        self:GettingInfoFromRuin()
    end
end

function repair_facility_drone:GettingInfoFromBaseToUpgrade(eventEntity)

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
        if ( baseDatabase == nil ) then
            goto continue
        end

        local newPositionX = 0
        local newPositionZ = 0

        if ( baseDatabase and baseDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = baseDatabase:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function repair_facility_drone:GettingInfoFromRuin()

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for ruinEntity in Iter( entities ) do

        local blueprintName = EntityService:GetBlueprintName(ruinEntity)
        if ( blueprintName ~= selfRuinsBlueprint ) then
            goto continue
        end

        local ruinPosition = EntityService:GetPosition(ruinEntity)
        if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
            goto continue
        end

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )
        if ( ruinDatabase == nil ) then
            goto continue
        end

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local newPositionX = 0
        local newPositionZ = 0

        if ( ruinDatabase and ruinDatabase:HasVector(selfLowName .. "_center_point_vector") ) then
            local vector = ruinDatabase:GetVector(selfLowName .. "_center_point_vector")

            newPositionX = vector.x
            newPositionZ = vector.z
        end

        self:SetCenterPointPosition( newPositionX, newPositionZ )

        ::continue::
    end
end

function repair_facility_drone:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetWasSold() == true) then
        return
    end

    local selfBlueprintName = EntityService:GetBlueprintName(self.entity)

    local selfLowName = BuildingService:FindLowUpgrade( selfBlueprintName )

    local selfRuinsBlueprint = selfBlueprintName .. "_ruins"

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 2)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local entities = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for ruinEntity in Iter( entities ) do

        local blueprintName = EntityService:GetBlueprintName(ruinEntity)
        if ( blueprintName ~= selfRuinsBlueprint ) then
            goto continue
        end

        local ruinPosition = EntityService:GetPosition(ruinEntity)
        if ( ruinPosition.x ~= position.x or ruinPosition.y ~= position.y or ruinPosition.z ~= position.z ) then
            goto continue
        end

        local ruinDatabase = EntityService:GetDatabase( ruinEntity )
        if ( ruinDatabase == nil ) then
            goto continue
        end

        local ruinDatabaseBlueprint = ruinDatabase:GetStringOrDefault("blueprint", "")
        if ( ruinDatabaseBlueprint ~= selfBlueprintName ) then
            goto continue
        end

        local pointPosition = EntityService:GetPosition( self.pointEntity )
        local selfPosition = EntityService:GetPosition( self.entity )

        local pointPositionVector = {
            x = pointPosition.x - selfPosition.x,
            y = 0,
            z = pointPosition.z - selfPosition.z
        }

        ruinDatabase:SetVector(selfLowName .. "_center_point_vector", pointPositionVector)

        ::continue::
    end
end

-- #endregion Drone Point

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
