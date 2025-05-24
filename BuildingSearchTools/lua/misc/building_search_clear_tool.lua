local building_search_base = require("lua/misc/building_search_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'building_search_clear_tool' ( building_search_base )

function building_search_clear_tool:__init()
    building_search_base.__init(self,self)
end

function building_search_clear_tool:OnInit()

    self.popupShown = false

    self.modeBuilding = 0
    self.modeBuildingGroup = 1
    self.modeBuildingCategory = 2
    self.modeAll = 3
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding, self.modeBuildingGroup, self.modeBuildingCategory, self.modeAll }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray,self.modeBuildingLastSelected, self.selector)

    self.configName = "$building_search_tool_config"

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedMode = selectorDB:GetIntOrDefault(self.configName, self.modeAll)
    self.selectedMode = self:CheckModeValueExists(self.selectedMode)

    selectorDB:SetInt(self.configName, self.selectedMode)

    self:UpdateMarker()
end

function building_search_clear_tool:UpdateMarker()

    local messageText = ""
    local markerBlueprint = ""

    local buildingIconVisible = 1
    local buildingIcon = ""

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local indexBuilding = self.selectedMode - self.modeBuildingLastSelected

        local buildingNumber = #self.lastSelectedBuildingsArray - indexBuilding

        local buildingBlueprint = self.lastSelectedBuildingsArray[buildingNumber]

        self.lastSelectedBuilding = buildingBlueprint

        local menuIcon, buildingDescRef = self:GetMenuIcon( buildingBlueprint )

        messageText = "${gui/hud/building_search/clear_mark_buildings} ${" .. buildingDescRef.localization_id .. "}"

        buildingIcon = menuIcon

        markerBlueprint = "misc/marker_selector_building_search_last_tool"

    elseif ( self.selectedMode == self.modeBuilding ) then

        buildingIcon = "gui/hud/tools_icons/building_search_clear_tool"

        messageText = "gui/hud/building_search/clear_building"
        markerBlueprint = "misc/marker_selector_building_search_clear_tool"

    elseif ( self.selectedMode == self.modeBuildingGroup ) then

        buildingIcon = "gui/hud/tools_icons/building_search_clear_group_tool"

        messageText = "gui/hud/building_search/clear_building_group"
        markerBlueprint = "misc/marker_selector_building_search_clear_group_tool"

    elseif ( self.selectedMode == self.modeBuildingCategory ) then

        buildingIcon = "gui/hud/tools_icons/building_search_clear_category_tool"

        messageText = "gui/hud/building_search/clear_building_category"
        markerBlueprint = "misc/marker_selector_building_search_clear_category_tool"

    else

        buildingIcon = "gui/hud/tools_icons/building_search_clear_all_tool"

        messageText = "gui/hud/building_search/clear_all"
        markerBlueprint = "misc/marker_selector_building_search_clear_all_tool"
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

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_icon_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)

    markerDB:SetInt("menu_visible", 1)
    markerDB:SetString("message_text", messageText)
end

function building_search_clear_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool", self.entity )
    end
end

function building_search_clear_tool:AddedToSelection( entity )

    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function building_search_clear_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function building_search_clear_tool:FilterSelectedEntities( selectedEntities )

    local result = {}

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return result
    end

    for entity in Iter( selectedEntities ) do

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName(entity)

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto continue
        end

        Insert(result, entity)

        ::continue::
    end

    return result
end

function building_search_clear_tool:OnUpdate()

end

function building_search_clear_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then

        local buildingsList = self:FindEntitiesToMark(self.lastSelectedBuilding, false)

        for building in Iter( buildingsList ) do

            self:RemoveMarkEntity(building)
        end

        return
    end

    if ( self.selectedMode == self.modeAll ) then

        self:RemoveAllMarkers()

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

        if ( self.selectedMode == self.modeBuilding or self.selectedMode == self.modeBuildingGroup ) then

            if ( blueprintName ~= "" ) then

                local isGroup = (self.selectedMode == self.modeBuildingGroup)

                self:AddBlueprintToLastList(blueprintName, self.selector)

                self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray,self.modeBuildingLastSelected, self.selector)

                local buildingsList = self:FindEntitiesToMark(blueprintName, isGroup)

                for building in Iter( buildingsList ) do

                    self:RemoveMarkEntity(building)
                end
            end
        end

        if ( self.selectedMode == self.modeBuildingCategory ) then

            if ( buildingDescRef.category ~= "" ) then

                local buildingsList = self:FindEntitiesByCategoryToMark(buildingDescRef.category)

                for building in Iter( buildingsList ) do

                    self:RemoveMarkEntity(building)
                end
            end
        end

        ::continue::
    end
end

function building_search_clear_tool:OnRotateSelectorRequest(evt)

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

    local selectorDB = EntityService:GetDatabase( self.selector )

    if ( newValue >= self.modeBuildingLastSelected ) then
        selectorDB:SetInt(self.configName, self.modeBuildingLastSelected)
    else
        selectorDB:SetInt(self.configName, newValue)
    end

    self:UpdateMarker()
end

function building_search_clear_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function building_search_clear_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( building_search_base.OnRelease ) then
        building_search_base.OnRelease(self)
    end
end

return building_search_clear_tool