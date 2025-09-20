local repair_all_map_base = require("lua/misc/repair_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/repair_all_map_tools_last_selected_blueprints_utils.lua")

class 'repair_all_map_picker_tool' ( repair_all_map_base )

function repair_all_map_picker_tool:__init()
    repair_all_map_base.__init(self,self)
end

function repair_all_map_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    self.modeBuilding = 0
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function repair_all_map_picker_tool:SetBuildingIcon()

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

            messageText = "${gui/hud/repair_all_map/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${gui/hud/repair_all_map/current_building}:\n${" .. buildingDescRef.localization_id .. "}"
        end
    end

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    markerDB:SetInt("menu_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function repair_all_map_picker_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/current" )
end

function repair_all_map_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function repair_all_map_picker_tool:FindEntitiesToSelect( selectorComponent )

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return {}
    end

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale - 0.5)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ConcatUnique( selectedItems, ruins)

    return selectedItems
end

function repair_all_map_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = self:GetBlueprintName(entity)
        if ( blueprintName == "" ) then
            goto continue
        end

        if ( self:IsBlueprintInList(blueprintName) ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function repair_all_map_picker_tool:OnUpdate()
    self:HighlightRuins()
end

function repair_all_map_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        if ( self:ChangeSelector(self.lastSelectedBuilding) ) then

            return
        end

        return
    end

    for entity in Iter( self.selectedEntities ) do

        local blueprintName = self:GetBlueprintName(entity)
        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
        if ( baseBuildingDesc ~= nil ) then
            buildingDesc = baseBuildingDesc
        end

        local buildingDescHelper = reflection_helper(buildingDesc)

        blueprintName = buildingDescHelper.bp or ""

        if ( self:ChangeSelector(blueprintName) ) then

            return
        end

        ::continue::
    end
end

function repair_all_map_picker_tool:ChangeSelector(blueprintName)

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

function repair_all_map_picker_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

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

function repair_all_map_picker_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function repair_all_map_picker_tool:OnRotateSelectorRequest(evt)

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

function repair_all_map_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function repair_all_map_picker_tool:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        self:RemovedFromSelection( ruinEntity )

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        self:SetEntitySelectedMaterial( ruinEntity, "hologram/grey" )
    end

    self.previousMarkedRuins = ruinsList
end

function repair_all_map_picker_tool:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local ruinsList = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( database == nil ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        Insert( result, ruinEntity )

        ::continue::
    end

    return result
end

function repair_all_map_picker_tool:OnRelease()

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do

            self:RemovedFromSelection( ruinEntity )
        end
    end
    self.previousMarkedRuins = {}

    if ( repair_all_map_base.OnRelease ) then
        repair_all_map_base.OnRelease(self)
    end
end

return repair_all_map_picker_tool
 