local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/building_utils.lua")

class 'harvesting_buildings_drone_point_picker_tool' ( tool )

function harvesting_buildings_drone_point_picker_tool:__init()
    tool.__init(self,self)
end

function harvesting_buildings_drone_point_picker_tool:OnInit()
    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)
    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.buildingBlueprint = self.data:GetStringOrDefault("buildingBlueprint", "") or ""
    self.buildingLowUpgrade = self.data:GetStringOrDefault("buildingLowUpgrade", "") or ""

    self.pickedBuildings = {}

    self.entitiesShowBuildingDisplayRadiusAround = {}
    self.tickCurrent = 0
    self.tickMod = 5

    local blueprintDatabase = EntityService:GetBlueprintDatabase( self.buildingBlueprint )

    local min, max = self:GetBuildingDisplayRadius(blueprintDatabase)
    self.display_effect_blueprint = ""
    self.display_radius_group = ""

    self.display_radius_min = min
    self.display_radius_max = max

    if max ~= nil then
        self.display_effect_blueprint = blueprintDatabase:GetStringOrDefault( "display_radius_blueprint", "effects/decals/range_circle" )
        self.display_radius_group = blueprintDatabase:GetStringOrDefault("display_radius_group", "") or ""
    end

    if ( self.display_radius_group ~= "" ) then
        ShowBuildingDisplayRadiusAround( self.entity, self.buildingBlueprint )
    end
end

function harvesting_buildings_drone_point_picker_tool:GetBuildingDisplayRadius( blueprintDatabase )

    if blueprintDatabase ~= nil then
        for key in Iter({ "heal_radius", "range", "radius", "drone_search_radius" }) do
            if blueprintDatabase:HasFloat( key ) then
                return 0, blueprintDatabase:GetFloat( key )
            end
        end
    end

    return nil, nil
end

function harvesting_buildings_drone_point_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function harvesting_buildings_drone_point_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function harvesting_buildings_drone_point_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function harvesting_buildings_drone_point_picker_tool:AddedToSelection( entity )
end

function harvesting_buildings_drone_point_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function harvesting_buildings_drone_point_picker_tool:OnUpdate()

    if ( self.display_radius_group == "" ) then
        self:ShowBuildingDisplayRadiusWithoutGroup()
    end

    for entity in Iter( self.pickedBuildings ) do

        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_current", "selected")
        end
    end

    for entity in Iter( self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        local isInList = ( IndexOf( self.pickedBuildings, entity ) ~= nil )

        if ( isInList ) then

            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
            end
        else
            -- Mark candidate to add to template
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        end
    end
end

function harvesting_buildings_drone_point_picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local towerDronePointsParents = self:FindTowerDronePointsParents(selectorComponent.position)

    ConcatUnique( selectedItems, towerDronePointsParents )

    return selectedItems
end

function harvesting_buildings_drone_point_picker_tool:FindTowerDronePointsParents(position)

    local position = EntityService:GetPosition(self.entity)

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local vectorBounds = VectorMulByNumber(boundsSize , 0.5)

    local min = VectorSub(position, vectorBounds)
    local max = VectorAdd(position, vectorBounds)

    local result = {}

    local entities = FindService:FindEntitiesByBlueprintInBox( "buildings/tower_drone_point", min, max )

    for entity in Iter( entities ) do

        local parentEntity = EntityService:GetParent(entity)
        if ( parentEntity == nil or parentEntity == INVALID_ID ) then
            goto continue
        end

        local parentBlueprintName = EntityService:GetBlueprintName(parentEntity)

        local buildingDesc = BuildingService:GetBuildingDesc( parentBlueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( parentBlueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        Insert(result, parentEntity)

        ::continue::
    end

    return result
end

function harvesting_buildings_drone_point_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function harvesting_buildings_drone_point_picker_tool:ShowBuildingDisplayRadiusWithoutGroup()

    local performFind = (self.tickCurrent % self.tickMod) == 0

    if ( performFind ) then

        self.tickCurrent = 0
    end

    self.tickCurrent = self.tickCurrent + 1

    if ( not performFind ) then
        return
    end

    local newList = self:FindBuildingLowUpgrade()

    self.entitiesShowBuildingDisplayRadiusAround = self.entitiesShowBuildingDisplayRadiusAround or {}

    for entity in Iter( self.entitiesShowBuildingDisplayRadiusAround ) do

        if ( IndexOf( newList, entity ) ~= nil ) then
            goto continue
        end

        HideBuildingDisplayRadiusAround( self.entity, entity )

        ::continue::
    end

    for entity in Iter( newList ) do
        ShowBuildingDisplayRadiusAround( self.entity, entity )
    end

    self.entitiesShowBuildingDisplayRadiusAround = newList
end

function harvesting_buildings_drone_point_picker_tool:FindBuildingLowUpgrade()

    local buildings = FindService:FindEntitiesByType( "building" )

    local result = {}

    for entity in Iter( buildings ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName ~= self.buildingLowUpgrade ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function harvesting_buildings_drone_point_picker_tool:OnActivateSelectorRequest()

    self.activated = true

    for entity in Iter( self.selectedEntities ) do

        self:OnActivateEntity( entity, true, true )
    end

    self:ShowDisplayRadiusComponent()
end

function harvesting_buildings_drone_point_picker_tool:OnActivateEntity( entity, removalEnabled, ignoreDisplayingRadiusComponent )

    removalEnabled = removalEnabled or false
    ignoreDisplayingRadiusComponent = ignoreDisplayingRadiusComponent or false

    if ( IndexOf( self.pickedBuildings, entity ) == nil ) then

        Insert( self.pickedBuildings, entity )

        local params = {
            isBuildingSelected = "1"
        }

        QueueEvent( "LuaGlobalEvent", entity, "DronePointSelectedEvent", params )

    elseif (removalEnabled) then

        Remove( self.pickedBuildings, entity )

        local params = {
            isBuildingSelected = "0"
        }

        QueueEvent( "LuaGlobalEvent", entity, "DronePointSelectedEvent", params )
    end

    if ( not ignoreDisplayingRadiusComponent ) then

        self:ShowDisplayRadiusComponent()
    end
end

function harvesting_buildings_drone_point_picker_tool:ShowDisplayRadiusComponent()

    if ( #self.pickedBuildings > 0 ) then

        if self.display_radius_max ~= nil then
            local displayRadiusComponent = EntityService:GetComponent(self.childEntity, "DisplayRadiusComponent")

            if ( displayRadiusComponent == nil ) then

                displayRadiusComponent = EntityService:CreateComponent(self.childEntity, "DisplayRadiusComponent")

                local displayRadiusComponentRef = reflection_helper( displayRadiusComponent )
                displayRadiusComponentRef.min_radius = self.display_radius_min
                displayRadiusComponentRef.max_radius = self.display_radius_max
                displayRadiusComponentRef.max_radius_blueprint = self.display_effect_blueprint
            end
        end
    else

        EntityService:RemoveComponent( self.childEntity, "DisplayRadiusComponent" )
    end
end

function harvesting_buildings_drone_point_picker_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    if ( degree > 0 ) then

        if ( #self.pickedBuildings == 0 ) then
            return
        end

        local transform = EntityService:GetWorldTransform( self.entity )

        local params = {
            point_x = transform.position.x,
            point_z = transform.position.z
        }

        for entity in Iter( self.pickedBuildings ) do

            QueueEvent( "LuaGlobalEvent", entity, "DronePointChangeEvent", params )
        end
    else

        self:ClearPickedBuildings()
    end
end

function harvesting_buildings_drone_point_picker_tool:ClearPickedBuildings()

    local params = {
        isBuildingSelected = "0"
    }

    if ( self.pickedBuildings ~= nil) then
        for entity in Iter( self.pickedBuildings ) do

            QueueEvent( "LuaGlobalEvent", entity, "DronePointSelectedEvent", params )

            self:RemovedFromSelection( entity )
        end
    end
    self.pickedBuildings = {}

    EntityService:RemoveComponent( self.childEntity, "DisplayRadiusComponent" )
end

function harvesting_buildings_drone_point_picker_tool:OnRelease()

    if ( self.display_radius_group ~= "" ) then
        HideBuildingDisplayRadiusAround( self.entity, self.buildingBlueprint )
    end

    self:ClearPickedBuildings()

    if ( self.entitiesShowBuildingDisplayRadiusAround ~= nil) then
        for entity in Iter( self.entitiesShowBuildingDisplayRadiusAround ) do

            HideBuildingDisplayRadiusAround( self.entity, entity )
        end
    end
    self.entitiesShowBuildingDisplayRadiusAround = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return harvesting_buildings_drone_point_picker_tool
