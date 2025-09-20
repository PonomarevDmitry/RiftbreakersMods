local switch_all_map_base = require("lua/misc/switch_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/switch_all_map_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

class 'switch_all_map_switcher_tool' ( switch_all_map_base )

function switch_all_map_switcher_tool:__init()
    switch_all_map_base.__init(self,self)
end

function switch_all_map_switcher_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function switch_all_map_switcher_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.modeTurnOn = 0
    self.modeTurnOff = 1
    self.modeTurnGroupOn = 2
    self.modeTurnGroupOff = 3

    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeTurnOn, self.modeTurnOff, self.modeTurnGroupOn, self.modeTurnGroupOff }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeTurnOn

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()
end

function switch_all_map_switcher_tool:GetBaseEntitiesList()

    local result = {}

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return result
    end

    local hashResult = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( hashResult[entity] == true ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert( result, entity )
        hashResult[entity] = true

        ::continue::
    end

    return result
end

function switch_all_map_switcher_tool:UpdateMarker()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker")

    if ( self.selectedMode == self.modeTurnOn ) then

        markerBlueprint = self.data:GetString("marker_on")

    elseif ( self.selectedMode == self.modeTurnOff ) then

        markerBlueprint = self.data:GetString("marker_off")

    elseif ( self.selectedMode == self.modeTurnGroupOn ) then

        markerBlueprint = self.data:GetString("marker_group_on")

    elseif ( self.selectedMode == self.modeTurnGroupOff ) then

        markerBlueprint = self.data:GetString("marker_group_off")
    end

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

            messageText = "${gui/hud/switch_all_map/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            if ( self.selectedMode == self.modeTurnOn ) then

                messageText = "${gui/hud/switch_all_map/power_on}"

            elseif ( self.selectedMode == self.modeTurnOff ) then

                messageText = "${gui/hud/switch_all_map/power_off}"

            elseif ( self.selectedMode == self.modeTurnGroupOn ) then

                messageText = "${gui/hud/switch_all_map/building_group_power_on}"

            elseif ( self.selectedMode == self.modeTurnGroupOff ) then

                messageText = "${gui/hud/switch_all_map/building_group_power_off}"
            end
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
            buildingIconVisible = 1

            messageText = "${gui/hud/switch_all_map/building_not_selected}"

            if ( self.selectedMode == self.modeTurnOn ) then

                messageText = "${gui/hud/switch_all_map/power_on}: " .. messageText

            elseif ( self.selectedMode == self.modeTurnOff ) then

                messageText = "${gui/hud/switch_all_map/power_off}: " .. messageText

            elseif ( self.selectedMode == self.modeTurnGroupOn ) then

                messageText = "${gui/hud/switch_all_map/building_group_power_on}: " .. messageText

            elseif ( self.selectedMode == self.modeTurnGroupOff ) then

                messageText = "${gui/hud/switch_all_map/building_group_power_off}: " .. messageText
            end
        end
    else

        buildingIconVisible = 1

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        messageText = "${gui/hud/switch_all_map/building_not_selected}"

        if ( self.selectedMode == self.modeTurnOn ) then

            messageText = "${gui/hud/switch_all_map/power_on}: " .. messageText

        elseif ( self.selectedMode == self.modeTurnOff ) then

            messageText = "${gui/hud/switch_all_map/power_off}: " .. messageText

        elseif ( self.selectedMode == self.modeTurnGroupOn ) then

            messageText = "${gui/hud/switch_all_map/building_group_power_on}: " .. messageText

        elseif ( self.selectedMode == self.modeTurnGroupOff ) then

            messageText = "${gui/hud/switch_all_map/building_group_power_off}: " .. messageText
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

function switch_all_map_switcher_tool:SetTypeSetting()

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

function switch_all_map_switcher_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function switch_all_map_switcher_tool:AddedToSelection( entity )
end

function switch_all_map_switcher_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function switch_all_map_switcher_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:HasComponent(entity, "IsVisibleComponent") ) then

            self:SetEntitySelectedMaterial( entity, "hologram/current" )
        end
    end
end

function switch_all_map_switcher_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return result
    end

    local hashResult = {}

    local entitiesBuildings = self.entitiesBuildings or {}

    local setPower = ( self.selectedMode == self.modeTurnOn or self.selectedMode == self.modeTurnGroupOn )

    for entity in Iter( entitiesBuildings ) do

        if ( not EntityService:IsAlive(entity) ) then
            goto continue
        end

        if ( hashResult[entity] == true ) then
            goto continue
        end

        if( BuildingService:IsPlayerWorking( entity ) == setPower ) then
            goto continue
        end

        Insert( result, entity )
        hashResult[entity] = true

        ::continue::
    end

    return result
end

function switch_all_map_switcher_tool:IsEntityApproved( entity )

    if ( not PowerUtils:CanChangePower(entity)) then
        return false
    end

    if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
        return false
    end

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

    local isGroup = (self.selectedMode == self.modeTurnGroupOn or self.selectedMode == self.modeTurnGroupOff)

    if ( isGroup ) then

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

function switch_all_map_switcher_tool:OnRotateSelectorRequest(evt)

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

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()
end

function switch_all_map_switcher_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function switch_all_map_switcher_tool:OnActivateSelectorRequest()

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

    local setPower = ( self.selectedMode == self.modeTurnOn or self.selectedMode == self.modeTurnGroupOn )

    for entity in Iter( self.selectedEntities ) do

        if( BuildingService:IsPlayerWorking( entity ) ~= setPower ) then
            QueueEvent( "ChangeBuildingStatusRequest", entity, setPower )
        end

        ::continue::
    end
end

function switch_all_map_switcher_tool:ChangeSelector(blueprintName)

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

    self.selectedMode = self.modeTurnOn

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    return true
end

function switch_all_map_switcher_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

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

function switch_all_map_switcher_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function switch_all_map_switcher_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( switch_all_map_base.OnRelease ) then
        switch_all_map_base.OnRelease(self)
    end
end

return switch_all_map_switcher_tool