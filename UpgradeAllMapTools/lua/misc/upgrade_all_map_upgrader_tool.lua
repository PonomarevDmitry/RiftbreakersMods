local upgrade_all_map_base = require("lua/misc/upgrade_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/upgrade_all_map_tools_last_selected_blueprints_utils.lua")

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

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.modeBuilding = 0
    self.modeBuildingGroup = 1
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding, self.modeBuildingGroup }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:UpdateMarker()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function upgrade_all_map_upgrader_tool:UpdateMarker()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        markerBlueprint = self.data:GetString("marker_select")

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/upgrade_all_map/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        messageText = self:GetBuildinsDescription()

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
            buildingIconVisible = 1
        end
    else

        buildingIconVisible = 1

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        messageText = "${gui/hud/upgrade_all_map/building_not_selected}"
    end

    if ( self.selectedMode == self.modeBuildingGroup ) then

        markerBlueprint = self.data:GetString("marker_group")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/upgrade_all_map/building_group}:\n" .. messageText
        else

            messageText = "${gui/hud/upgrade_all_map/building_group}"
        end
    end

    if ( self.childEntity == nil or EntityService:GetBlueprintName(self.childEntity) ~= markerBlueprint ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    end

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("menu_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function upgrade_all_map_upgrader_tool:GetBuildinsDescription()

    local listIconsNames, hashIconsCount = self:GetIconsData()

    local buildingsIcons = ""

    local lineLength = 0
    local maxLineLength = 40

    for menuIcon in Iter( listIconsNames ) do

        local count = hashIconsCount[menuIcon]

        if ( count > 0 ) then

            if ( lineLength > 0 ) then

                lineLength = lineLength + 1
                buildingsIcons = buildingsIcons .. ","
            end

            local countString = tostring(count)
            local countStringLen = string.len(countString) + 2

            if ( lineLength + countStringLen + 1 > maxLineLength ) then

                buildingsIcons = buildingsIcons .. "\n"
                lineLength = 0

            else
                buildingsIcons = buildingsIcons .. " "
                lineLength = lineLength + 1
            end

            lineLength = lineLength + countStringLen

            buildingsIcons = buildingsIcons .. '<img="' .. menuIcon .. '">x' .. countString
        end
    end

    return buildingsIcons
end

function upgrade_all_map_upgrader_tool:GetIconsData()

    self.selectedEntities = self.selectedEntities or {}

    local upgradeCostsEntities = {}

    local listIconsNames = {}
    local hashIconsCount = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto labelContinue
        end

        upgradeCostsEntities[entity] = true

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then

            goto labelContinue
        end

        local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )
        if ( menuIcon ~= "" ) then

            if ( hashIconsCount[menuIcon] == nil ) then

                Insert( listIconsNames, menuIcon )

                hashIconsCount[menuIcon] = 0
            end

            hashIconsCount[menuIcon] = hashIconsCount[menuIcon] + 1
        end

        ::labelContinue::
    end

    return listIconsNames,hashIconsCount
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

    self:CreateMarkEntity(entity)
end

function upgrade_all_map_upgrader_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end

    self:RemoveMarkEntity(entity)
end

function upgrade_all_map_upgrader_tool:OnUpdate()

    self:UpdateMarker()

    self.upgradeCosts = {}

    local upgradeCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( upgradeCostsEntities[entity] ~= nil ) then
            goto labelContinue
        end

        upgradeCostsEntities[entity] = true

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto labelContinue
        end




        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then

            self:SetEntitySelectedMaterial( entity, "hologram/active" )

            goto labelContinue
        end

        self:SetEntitySelectedMaterial( entity, "hologram/pass" )

        local list = BuildingService:GetUpgradeCosts( entity, self.playerId )
        for resourceCost in Iter(list) do

            if ( self.upgradeCosts[resourceCost.first] == nil ) then
                self.upgradeCosts[resourceCost.first] = 0
            end

            self.upgradeCosts[resourceCost.first] = self.upgradeCosts[resourceCost.first] + resourceCost.second
        end

        ::labelContinue::
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

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return {}
    end

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto labelContinue
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function upgrade_all_map_upgrader_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then

        if not ( is_server and is_client ) then

            local mapperName = "ForceNetReplicateNextFrameRequest"

            QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
        end

        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode ~= BM_COMPLETED ) then
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

    local buildingDescRef = reflection_helper( buildingDesc )

    local resourceRequirement = buildingDescRef.resource_requirement
    if ( resourceRequirement ~= nil or resourceRequirement.count > 0 ) then

        local buildingStatusComponent = EntityService:GetComponent( entity, "BuildingStatusComponent" )
        if ( buildingStatusComponent ~= nil ) then

            local buildingStatusComponentRef = reflection_helper( buildingStatusComponent )

            if ( buildingStatusComponentRef ~= nil and buildingStatusComponentRef.status and buildingStatusComponentRef.status.missing_resources and buildingStatusComponentRef.status.missing_resources.count > 0 ) then

                for i = 1,resourceRequirement.count do

                    local resource = resourceRequirement[i] or ""

                    if ( resource ~= "" ) then

                        for j = 1,buildingStatusComponentRef.status.missing_resources.count do

                            local missingResource = buildingStatusComponentRef.status.missing_resources[j] or ""

                            if ( missingResource ~= "" and missingResource == resource ) then

                                return false
                            end
                        end
                    end
                end
            end
        end
    end

    local isGroup = (self.selectedMode == self.modeBuildingGroup)

    if ( isGroup ) then

        if ( self:IsBlueprintInLowNameList(blueprintName) ) then
            return true
        end

        if ( self.selectedType == "tower" or self.selectedType == "trap" or self.selectedType == "gate" ) then

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

    local selectedMode = self:CheckModeValueExists(self.selectedMode)

    local index = IndexOf( self.modeValuesArray, selectedMode )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #self.modeValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = self.modeValuesArray[newIndex]

    self.selectedMode = newValue

    self:UpdateMarker()
end

function upgrade_all_map_upgrader_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function upgrade_all_map_upgrader_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        if ( self:ChangeSelector(self.lastSelectedBuilding) ) then

            return
        end

        return
    end

    if ( #self.selectedEntities == 0 ) then
        return
    end

    local distances = {}

    for entity in Iter( self.selectedEntities ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(self.selectedEntities, sorter)

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( buildingDescRef.limit_name == "hq" ) then
            goto labelContinue
        end

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto labelContinue
        end

        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto labelContinue
        end

        if ( is_server and is_client ) then

            QueueEvent( "UpgradeBuildingRequest", entity, self.playerId )

        else

            local mapperName = "UpgradeAllMapToolsForceUpgrade|" .. tostring(self.playerId)

            QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
        end

        ::labelContinue::
    end
end

function upgrade_all_map_upgrader_tool:ChangeSelector(blueprintName)

    if ( blueprintName == "" or blueprintName == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.template_name, blueprintName )

    self.selectedBuildingBlueprint = blueprintName

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self:AddBlueprintToLastList(blueprintName, self.selector)

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:UpdateMarker()

    return true
end

function upgrade_all_map_upgrader_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

    self.lastSelectedBuildingsArray = LastSelectedBlueprintsListUtils:GetCurrentList(self.list_name, selector)

    if ( self.selectedBuildingBlueprint ~= "" and self.selectedBuildingBlueprint ~= nil and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        LastSelectedBlueprintsListUtils:RemoveBuildingAndUpgradesFromList(self.lastSelectedBuildingsArray, self.selectedBuildingBlueprint)
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedBuildingsArray-1 do

        Insert(modeValuesArray, (modeBuildingLastSelected + index))
    end

    return modeValuesArray
end

function upgrade_all_map_upgrader_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function upgrade_all_map_upgrader_tool:CreateMarkEntity( building )

    local markerBlueprintName = "misc/marked_building_to_upgrade_minimap_icon"

    local childreen = EntityService:GetChildren(building, true)

    for entity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName == markerBlueprintName ) then
            return
        end
    end

    local markEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, building )
end

function upgrade_all_map_upgrader_tool:RemoveMarkEntity( building )

    local markerBlueprintName = "misc/marked_building_to_upgrade_minimap_icon"

    local childreen = EntityService:GetChildren(building, true)

    for entity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName == markerBlueprintName ) then

            EntityService:RemoveEntity( entity )
        end
    end
end

function upgrade_all_map_upgrader_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( upgrade_all_map_base.OnRelease ) then
        upgrade_all_map_base.OnRelease(self)
    end
end

return upgrade_all_map_upgrader_tool