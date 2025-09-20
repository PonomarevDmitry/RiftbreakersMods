local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/switch_all_map_tools_last_selected_blueprints_utils.lua")
local PowerUtils = require("lua/utils/power_utils.lua")

class 'switch_all_map_cat_switcher_tool' ( tool )

function switch_all_map_cat_switcher_tool:__init()
    tool.__init(self,self)
end

function switch_all_map_cat_switcher_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function switch_all_map_cat_switcher_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.categoryTemplate = self.data:GetStringOrDefault("category_name", "") or ""

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.selectedCategory = ""

    self.categoryNotSelected = false

    self.modeTurnOn = 0
    self.modeTurnOff = 1

    self.modeSelectLast = 100

    if ( self.categoryTemplate ~= "" ) then

        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

        self.selectedCategory = selectorDB:GetStringOrDefault( self.categoryTemplate, "" ) or ""

        self.defaultModesArray = { self.modeTurnOn, self.modeTurnOff }

        self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)
    else
        self.modeValuesArray = { self.modeTurnOn, self.modeTurnOff }
    end

    self.selectedMode = self.modeTurnOn

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()
end

function switch_all_map_cat_switcher_tool:GetBaseEntitiesList()

    local result = {}
    local hashResult = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( hashResult[entity] == true ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
            goto continue
        end

        if ( EntityService:GetComponent(entity, "ResourceConverterComponent") == nil ) then
            goto continue
        end

        if ( not PowerUtils:CanChangePower(entity) ) then
            goto continue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        local lowName = BuildingService:FindLowUpgrade( blueprintName )
        if ( lowName == "short_range_radar" ) then
            goto continue
        end

        if ( self.categoryTemplate ~= "" ) then

            if ( buildingDescRef.category ~= self.selectedCategory ) then

                goto continue
            end
        end

        Insert( result, entity )
        hashResult[entity] = true

        ::continue::
    end

    return result
end

function switch_all_map_cat_switcher_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_violet", self.entity )
    end
end

function switch_all_map_cat_switcher_tool:UpdateMarker()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker")

    if ( self.selectedMode == self.modeTurnOn ) then

        markerBlueprint = self.data:GetString("marker_on")

    elseif ( self.selectedMode == self.modeTurnOff ) then

        markerBlueprint = self.data:GetString("marker_off")
    end

    if ( self.categoryTemplate == "" ) then

        if ( self.selectedMode == self.modeTurnOn ) then

            markerBlueprint = self.data:GetString("marker_on")

            messageText = "${gui/hud/switch_all_map/power_on}"

        elseif ( self.selectedMode == self.modeTurnOff ) then

            markerBlueprint = self.data:GetString("marker_off")

            messageText = "${gui/hud/switch_all_map/power_off}"
        end

    elseif ( self.selectedMode >= self.modeSelectLast ) then

        markerBlueprint = self.data:GetString("marker_select")

        local indexCategory = self.selectedMode - self.modeSelectLast

        local categoryNumber = #self.lastSelectedCategoriesArray - indexCategory

        self.lastSelectedCategory = self.lastSelectedCategoriesArray[categoryNumber]


        local menuIcon = "gui/hud/building_icons/" .. self.lastSelectedCategory ..  "_structures_neutral"

        messageText = "${gui/hud/switch_all_map/last_building} " .. tostring(indexCategory + 1)

        buildingIcon = menuIcon
        buildingIconVisible = 1

    elseif ( self.selectedCategory ~= "" ) then

        local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

        if ( ResourceManager:ResourceExists("Material", menuIcon) ) then

            buildingIcon = menuIcon
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
        end

        if ( self.selectedMode == self.modeTurnOn ) then

            messageText = "${gui/hud/switch_all_map/power_on}"

        elseif ( self.selectedMode == self.modeTurnOff ) then

            messageText = "${gui/hud/switch_all_map/power_off}"
        end

        buildingIconVisible = 1
    else

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        buildingIconVisible = 1

        messageText = "${gui/hud/switch_all_map/building_category_not_selected}"

        if ( self.selectedMode == self.modeTurnOn ) then

            messageText = "${gui/hud/switch_all_map/power_on}: " .. messageText

        elseif ( self.selectedMode == self.modeTurnOff ) then

            messageText = "${gui/hud/switch_all_map/power_off}: " .. messageText
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

    markerDB:SetInt("menu_visible", 1)

    markerDB:SetInt("building_icon_visible", buildingIconVisible)
    markerDB:SetString("building_icon", buildingIcon)
    markerDB:SetString("message_text", messageText)
end

function switch_all_map_cat_switcher_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function switch_all_map_cat_switcher_tool:AddedToSelection( entity )
end

function switch_all_map_cat_switcher_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function switch_all_map_cat_switcher_tool:OnUpdate()

    for entity in Iter( self.selectedEntities ) do

        if ( EntityService:HasComponent(entity, "IsVisibleComponent") ) then

            EntityService:SetMaterial( entity, "hologram/current", "selected" )

            local children = EntityService:GetChildren( entity, true )
            for child in Iter( children ) do
                if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
                    EntityService:SetMaterial( child, "hologram/current", "selected" )
                end
            end
        end

        ::continue::
    end
end

function switch_all_map_cat_switcher_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}
    local hashResult = {}

    if ( self.selectedMode >= self.modeSelectLast ) then
        return result
    end

    local entitiesBuildings = self.entitiesBuildings or {}

    local setPower = ( self.selectedMode == self.modeTurnOn )

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

function switch_all_map_cat_switcher_tool:OnActivateSelectorRequest()

    if ( self.categoryTemplate ~= "" and self.categoryTemplate ~= nil and self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedCategory) ) then

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

    local setPower = ( self.selectedMode == self.modeTurnOn )

    for entity in Iter( self.selectedEntities ) do

        if( BuildingService:IsPlayerWorking( entity ) ~= setPower ) then
            QueueEvent( "ChangeBuildingStatusRequest", entity, setPower )
        end
    end
end

function switch_all_map_cat_switcher_tool:ChangeSelector(category)

    if ( category == "" or category == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.categoryTemplate, category )

    self.selectedCategory = category

    self:AddCategoryToLastList(category, self.selector)

    self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeTurnOn

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    return true
end

function switch_all_map_cat_switcher_tool:FillLastCategoriesList(defaultModesArray, modeSelectLast, selector)

    self.lastSelectedCategoriesArray = LastSelectedBlueprintsListUtils:GetCurrentList(self.list_name, selector)

    if ( self.selectedCategory ~= "" and self.selectedCategory ~= nil ) then

        Remove( self.lastSelectedCategoriesArray, self.selectedCategory )
    end

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedCategoriesArray-1 do

        Insert(modeValuesArray, (modeSelectLast + index))
    end

    return modeValuesArray
end

function switch_all_map_cat_switcher_tool:AddCategoryToLastList(category, selector)

    LastSelectedBlueprintsListUtils:AddStringToList(self.list_name, selector, category)
end

function switch_all_map_cat_switcher_tool:OnRotateSelectorRequest(evt)

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

function switch_all_map_cat_switcher_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function switch_all_map_cat_switcher_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return switch_all_map_cat_switcher_tool