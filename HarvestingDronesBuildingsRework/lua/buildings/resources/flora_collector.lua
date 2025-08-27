require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")
require("lua/utils/area_center_point_utils.lua")

local drone_spawner_building = require("lua/buildings/drone_spawner_building.lua")
class 'flora_collector' ( drone_spawner_building )

function flora_collector:__init()
    drone_spawner_building.__init(self,self)
end

function flora_collector:CreateDebugStateMachine()
    if self.debug == nil then
        self.debug = self:CreateStateMachine();
        self.debug:AddState("debug", { execute="OnDebugExecute" } );
    end
end

function flora_collector:OnLoad()
    drone_spawner_building.OnLoad(self)

    self:CreateDebugStateMachine()

    self:CreateCenterPoint()
    self:RegisterEventHandlers()
end

function flora_collector:OnInit()
    drone_spawner_building.OnInit( self )

    self.fsm = self:CreateStateMachine();
    self.fsm:AddState( "update_production", { execute="OnUpdateProductionExecute", interval=1.0 } )
    self.fsm:ChangeState("update_production")

    self:CreateDebugStateMachine()

    self.harvested_resources = {}

    self:CreateCenterPoint()
    self:RegisterEventHandlers()
end

function flora_collector:RegisterEventHandlers()

    self:RegisterHandler( self.entity, "LuaGlobalEvent", "OnDronePointEvent")

    self:RegisterHandler( self.entity, "BuildingStartEvent", "OnBuildingStartEventGettingInfo" )
    self:RegisterHandler( self.entity, "BuildingRemovedEvent", "OnBuildingRemovedEventTrasferingInfoToRuin" )

    self:RegisterHandler( self.entity, "ActivateEntityRequest", "OnActivateEntityRequestDronePoint" )
    self:RegisterHandler( self.entity, "DeactivateEntityRequest", "OnDeactivateEntityRequestDronePoint" )
end

function flora_collector:OnDebugExecute()
    local message = "COLLECTED:\n"
    for resource,values in pairs( self.harvested_resources ) do
        message = message .. resource .. " = ";
        for value in Iter(self.harvested_resources[resource]) do
            message = message .. tostring(value.amount) .. ", ";
        end

        message = message .. "\n";
    end

    LogService:DebugText(self.entity,message)
end

function flora_collector:TimeoutHarvestHistory(time)
    for resourceName, data in pairs(self.harvested_resources) do
        for i, value in ipairs( data ) do
            if (time - value.timepoint) > 60.0 then
                table.remove(data, i)
            end
        end

        if #data == 0 then
            self.harvested_resources[resourceName] = nil
            self.data:RemoveKey("harvested_resources." .. resourceName);
        end
    end
end

function flora_collector:GetHarvestHistoryAverage(resourceName, time)
    local totalValue = 0.0
    local totalTime = 0.0
    for value in Iter(self.harvested_resources[resourceName] or {}) do
        totalValue = totalValue + value.amount
        totalTime = math.max(time - value.timepoint, totalTime);
    end

    if totalTime <= 0.0 then
        return { value = 0.0, time = 1.0 }
    end

    return { value = totalValue * 1.0, time = totalTime * 1.0 };
end

function flora_collector:OnUpdateProductionExecute(state, dt)
    if g_debug_resource_harvester then
        self.debug:ChangeState("debug")
    else
        self.debug:Deactivate()
    end

    local time = GetLogicTime();

    local keys = self.data:GetFloatKeys()

    local harvested_resources = ""
    for key in Iter( keys ) do
        local index = string.find( key, "harvested_resources.");
        if index ~= nil then
            local resource_name = string.gsub( key, "harvested_resources.", "" );
            harvested_resources = harvested_resources .. "," .. resource_name

            local harvested_amount = self.data:GetFloat(key);
            if harvested_amount > 0.0 then
                self.data:SetFloat(key, 0.0);

                local harvested_history = self.harvested_resources[resource_name] or {};
                self.harvested_resources[resource_name] = harvested_history;

                table.insert( harvested_history, { amount=harvested_amount, timepoint=time } );
            end

            local average = self:GetHarvestHistoryAverage( resource_name, time );
            self.data:SetString("production_group.rows." .. resource_name .. ".type", "production" );
            self.data:SetString("production_group.rows." .. resource_name .. ".resource", resource_name );
            self.data:SetString("production_group.rows." .. resource_name .. ".value", string.format("%.1f", average.value / average.time) );
        end
    end

    self.data:SetString("stat_categories", "production_group")
    self.data:SetString("production_group.rows", harvested_resources );

    self:TimeoutHarvestHistory( time );
end

-- #region Drone Point

function flora_collector:CreateCenterPoint()

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

                break
            end
        end
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

function flora_collector:OnDronePointEvent(evt)

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

function flora_collector:OnActivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = true

    self:UpdateDronePointSkinMaterial()
end

function flora_collector:OnDeactivateEntityRequestDronePoint( evt )

    if ( evt:GetEntity() ~= self.entity) then
        return
    end

    self.dronePointSelected = false

    self:UpdateDronePointSkinMaterial()
end

function flora_collector:SetCenterPointPosition( newPositionX, newPositionZ )

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

function flora_collector:UpdateDisplayRadiusVisibility( show, entity )

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

            local displayRadiusComponent = EntityService:CreateComponent(self.pointEntity, "DisplayRadiusComponent")
            if ( displayRadiusComponent ~= nil ) then

                local displayRadiusComponentRef = reflection_helper( displayRadiusComponent )
                displayRadiusComponentRef.min_radius = self.display_radius_size.min
                displayRadiusComponentRef.max_radius = self.display_radius_size.max
                displayRadiusComponentRef.max_radius_blueprint = self.display_effect_blueprint
            end

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

function flora_collector:SetPointEntitySelectedSkin()

    self.dronePointSelected = self.dronePointSelected or false

    if ( self.dronePointSelected ) then

        EntityService:SetMaterial( self.pointEntity, "hologram/pass", "selected" )
        
    else

        EntityService:SetMaterial( self.pointEntity, "hologram/blue", "selected" )
    end
end

function flora_collector:UpdateDronePointSkinMaterial()

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

function flora_collector:CreateLinkEntity()

    local linkEntityBlueprintName = "effects/area_center_point_effects/area_center_point_link"

    if ( self.linkEntity == nil ) then

        local children = EntityService:GetChildren( self.entity, true )
        for child in Iter(children) do
            local blueprintName = EntityService:GetBlueprintName( child )
            if ( blueprintName == linkEntityBlueprintName and EntityService:GetParent( child ) == self.entity ) then

                self.linkEntity = child
                ItemService:SetInvisible(self.linkEntity, true)

                break
            end
        end
    end

    if ( self.linkEntity == nil ) then

        local team = EntityService:GetTeam( self.entity )
        self.linkEntity = EntityService:SpawnAndAttachEntity( linkEntityBlueprintName, self.entity, team)

        EntityService:CreateComponent(self.linkEntity, "EffectReferenceComponent")

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

function flora_collector:RemoveLinkEntity()

    if ( self.linkEntity == nil ) then
        return
    end

    EntityService:RemoveEntity(self.linkEntity)
    self.linkEntity = nil
end

function flora_collector:RepositionLinkEntity()

    if ( self.linkEntity == nil or self.pointEntity == nil ) then
        return
    end

    local selfPosition = EntityService:GetPosition(self.entity)
    local pointPosition = EntityService:GetPosition(self.pointEntity)

    local direction = VectorMulByNumber( Normalize( VectorSub( pointPosition, selfPosition ) ), 2.0 )
    selfPosition = VectorAdd(selfPosition, direction)

    local lightningComponent = EntityService:GetComponent(self.linkEntity, "LightningComponent")
    if ( lightningComponent == nil ) then
        return
    end

    local lightningComponentRef = reflection_helper(lightningComponent)
    if ( lightningComponentRef == nil or lightningComponentRef.lighning_vec == nil ) then
        return
    end

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

function flora_collector:OnBuildingStartEventGettingInfo(evt)

    local eventEntity = evt:GetEntity()

    if (evt:GetUpgrading() == true) then

        self:GettingInfoFromBaseToUpgrade(eventEntity)
    else
        self:GettingInfoFromRuin()
    end
end

function flora_collector:GettingInfoFromBaseToUpgrade(eventEntity)

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

        local baseDatabase = EntityService:GetOrCreateDatabase( entity )
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

function flora_collector:GettingInfoFromRuin()

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

        local ruinDatabase = EntityService:GetOrCreateDatabase( ruinEntity )
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

function flora_collector:OnBuildingRemovedEventTrasferingInfoToRuin(evt)

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

        local ruinDatabase = EntityService:GetOrCreateDatabase( ruinEntity )
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

function flora_collector:OnRelease()

    self:RemoveLinkEntity()

    if ( self.pointEntity ~= nil ) then

        EntityService:RemoveEntity( self.pointEntity )
        self.pointEntity = nil
    end

    if ( drone_spawner_building.OnRelease ) then
        drone_spawner_building.OnRelease(self)
    end
end

return flora_collector;
