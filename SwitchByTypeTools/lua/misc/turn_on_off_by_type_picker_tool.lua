local turn_on_off_by_type_base = require("lua/misc/turn_on_off_by_type_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/turn_by_type_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

class 'turn_on_off_by_type_picker_tool' ( turn_on_off_by_type_base )

function turn_on_off_by_type_picker_tool:__init()
    turn_on_off_by_type_base.__init(self,self)
end

function turn_on_off_by_type_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function turn_on_off_by_type_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function turn_on_off_by_type_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self:InitLowUpgradeList()

    self.modeBuilding = 0
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()
end

function turn_on_off_by_type_picker_tool:SetBuildingIcon()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/turn_by_type_tools/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/turn_by_type_tools/current_building}:\n${" .. buildingDescRef.localization_id .. "}"
        end
    end

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("menu_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function turn_on_off_by_type_picker_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/current" )
end

function turn_on_off_by_type_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function turn_on_off_by_type_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    if ( self.selectedMode ~= self.modeBuilding ) then
        return entities
    end

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
            goto continue
        end

        if ( not PowerUtils:CanChangePower(entity) ) then
            goto continue
        end

        if ( self:IsBlueprintInList(blueprintName) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function turn_on_off_by_type_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        if ( self:ChangeSelector(self.lastSelectedBuilding) ) then

            return
        end

        return
    end

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if ( baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescRef = reflection_helper(buildingDesc)

        blueprintName = buildingDescRef.bp or ""

        if ( self:ChangeSelector(blueprintName) ) then

            return
        end

        ::continue::
    end
end

function turn_on_off_by_type_picker_tool:ChangeSelector(blueprintName)

    if ( blueprintName == "" or blueprintName == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.template_name, blueprintName )

    self.selectedBuildingBlueprint = blueprintName

    self:InitLowUpgradeList()

    self:AddBlueprintToLastList(blueprintName, self.selector)

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()

    if ( self.next_tool ~= "" ) then

        local nextToolBuildingDescRef = reflection_helper( BuildingService:GetBuildingDesc( self.next_tool ) )

        QueueEvent( "ChangeSelectorRequest", self.selector, nextToolBuildingDescRef.bp, nextToolBuildingDescRef.ghost_bp )

        local nextToolBlueprintName = nextToolBuildingDescRef.bp

        local lowName = BuildingService:FindLowUpgrade( nextToolBlueprintName )

        if ( lowName == nextToolBlueprintName ) then
            lowName = nextToolBuildingDescRef.name
        end

        BuildingService:SetBuildingLastLevel( self.playerId, lowName, nextToolBuildingDescRef.name )

        QueueEvent( "ChangeBuildingRequest", self.selector, lowName )
    end

    return true
end

function turn_on_off_by_type_picker_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

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

function turn_on_off_by_type_picker_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function turn_on_off_by_type_picker_tool:OnRotateSelectorRequest(evt)

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

    self:SetBuildingIcon()
end

function turn_on_off_by_type_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

return turn_on_off_by_type_picker_tool
