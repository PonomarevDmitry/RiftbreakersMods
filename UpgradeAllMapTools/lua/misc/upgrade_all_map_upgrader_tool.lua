local upgrade_all_map_base = require("lua/misc/upgrade_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'upgrade_all_map_upgrader_tool' ( upgrade_all_map_base )

function upgrade_all_map_upgrader_tool:__init()
    upgrade_all_map_base.__init(self,self)
end

function upgrade_all_map_upgrader_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function upgrade_all_map_upgrader_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.isGroup = false
    self.currentChildIsGroup = nil

    self:UpdateMarker()
end

function upgrade_all_map_upgrader_tool:UpdateMarker()

    local messageText = ""
    local groupString = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.isGroup ) then
        messageText = "gui/hud/upgrade_all_map/building_group"
        groupString = "_by_group"

        markerBlueprint = self.data:GetString("marker_group")
    end

    if ( self.childEntity == nil or self.currentChildIsGroup ~= self.isGroup ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        
        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        self.currentChildIsGroup = self.isGroup
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", messageText)
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/upgrade_all_map/building_not_selected")
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/upgrade_all_map/building_not_selected")
    end
end

function upgrade_all_map_upgrader_tool:SetTypeSetting()

    self.selectedType = ""

    if ( self.selectedBuildingBlueprint == "" ) then
        return
    end

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( self.selectedBuildingBlueprint )
    if ( buildingDesc == nil ) then
        return
    end

    local buildingDescRef = reflection_helper( buildingDesc )

    if ( buildingDescRef.type == nil or buildingDescRef.type == "" ) then
        return
    end

    self.selectedType = buildingDescRef.type
end

function upgrade_all_map_upgrader_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function upgrade_all_map_upgrader_tool:AddedToSelection( entity )
end

function upgrade_all_map_upgrader_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function upgrade_all_map_upgrader_tool:OnUpdate()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto continue
        end

        upgradeCostsEntities[entity] = true

        local skinned = EntityService:IsSkinned(entity)



        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then

            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
            end

            goto continue
        end

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_pass", "selected" )
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

        local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.upgradeCosts[resourceCost.first] == nil ) then
                self.upgradeCosts[resourceCost.first] = 0
            end

            self.upgradeCosts[resourceCost.first] = self.upgradeCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, self.upgradeCosts )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateUpgradeCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateUpgradeCosts( self.corners, self.playerId, self.upgradeCosts )
    end
end

function upgrade_all_map_upgrader_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local distances = {}

    for entity in Iter( result ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(result, sorter)

    return result
end

function upgrade_all_map_upgrader_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName(entity)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
        return false
    end

    if ( self.isGroup ) then

        if ( self:IsBlueprintInLowNameList(blueprintName) ) then
            return true
        end

        if ( self.selectedType == "tower" or self.selectedType == "trap" or self.selectedType == "gate" ) then

            local buildingDescRef = reflection_helper( buildingDesc )

            if ( buildingDescRef.type == self.selectedType ) then
                return true
            end
        end
    else

        if ( self:IsBlueprintInList(blueprintName) ) then
            return true
        end
    end

    return false
end

function upgrade_all_map_upgrader_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentGroupValue = self:CheckGroupValueExists(self.isGroup)

    local groupValuesArray = self:GetGroupValuesArray()

    local index = IndexOf( groupValuesArray, currentGroupValue )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #groupValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = groupValuesArray[newIndex]

    self.isGroup = newValue

    self:UpdateMarker()
end

function upgrade_all_map_upgrader_tool:CheckGroupValueExists( groupValue )

    local groupValuesArray = self:GetGroupValuesArray()

    groupValue = groupValue or groupValuesArray[1]

    local index = IndexOf(groupValuesArray, groupValue )

    if ( index == nil ) then

        return groupValuesArray[1]
    end

    return groupValue
end

function upgrade_all_map_upgrader_tool:GetGroupValuesArray()

    if ( self.groupValuesArray == nil ) then

        self.groupValuesArray = { false, true }
    end

    return self.groupValuesArray
end

function upgrade_all_map_upgrader_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then
            goto continue
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

        QueueEvent( "UpgradeBuildingRequest", entity, self.playerId )

        ::continue::
    end
end

return upgrade_all_map_upgrader_tool