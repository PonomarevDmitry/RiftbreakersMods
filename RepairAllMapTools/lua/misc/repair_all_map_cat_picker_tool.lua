local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/repair_all_map_tools_last_selected_blueprints_utils.lua")

class 'repair_all_map_cat_picker_tool' ( tool )

function repair_all_map_cat_picker_tool:__init()
    tool.__init(self,self)
end

function repair_all_map_cat_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_cat_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_cat_picker_tool:OnInit()

    local marker_name = self.data:GetString("marker_name")
    self.childEntity = EntityService:SpawnAndAttachEntity(marker_name, self.entity)

    self.popupShown = false

    self.scaleMap = {
        1,
    }

    self.category_name = self.data:GetString("category_name")

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedCategory = selectorDB:GetStringOrDefault( self.category_name, "" ) or ""

    self.next_tool = self.data:GetStringOrDefault("next_tool", "") or ""

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.modeSelect = 0
    self.modeSelectLast = 100

    self.defaultModesArray = { self.modeSelect }

    self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function repair_all_map_cat_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function repair_all_map_cat_picker_tool:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    if ( self.selectedMode >= self.modeSelectLast ) then

        local indexCategory = self.selectedMode - self.modeSelectLast

        local categoryNumber = #self.lastSelectedCategoriesArray - indexCategory

        self.lastSelectedCategory = self.lastSelectedCategoriesArray[categoryNumber]


        local menuIcon = "gui/hud/building_icons/" .. self.lastSelectedCategory ..  "_structures_neutral"

        local messageText = "${gui/hud/repair_all_map/last_building} " .. tostring(indexCategory + 1)

        markerDB:SetString("building_icon", menuIcon)
        markerDB:SetString("message_text", messageText)
        markerDB:SetInt("menu_visible", 1)

    elseif ( self.selectedCategory ~= nil and self.selectedCategory ~= "" ) then

        local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

        local categoryLocalization = "gui/menu/controls/build_menu/" .. self.selectedCategory

        local messageText = "${gui/hud/repair_all_map/current_building}"

        markerDB:SetString("building_icon", menuIcon)
        markerDB:SetString("message_text", messageText)
        markerDB:SetInt("menu_visible", 1)
    else
        markerDB:SetString("building_icon", "")
        markerDB:SetString("message_text", "")
        markerDB:SetInt("menu_visible", 0)
    end
end

function repair_all_map_cat_picker_tool:AddedToSelection( entity )

    self:SetEntitySelectedMaterial( entity, "hologram/current" )
end

function repair_all_map_cat_picker_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function repair_all_map_cat_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function repair_all_map_cat_picker_tool:FindEntitiesToSelect( selectorComponent )

    if ( self.selectedMode ~= self.modeSelect ) then
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

function repair_all_map_cat_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        if ( IndexOf( entities, entity ) ~= nil ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local blueprintName = self:GetBlueprintName(entity)
        if ( blueprintName == "" ) then
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

        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto continue
        end

        if ( self.selectedCategory ~= "" ) then
            if ( buildingDescRef.category == self.selectedCategory ) then
                goto continue
            end
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function repair_all_map_cat_picker_tool:GetBlueprintName( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetOrCreateDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function repair_all_map_cat_picker_tool:OnUpdate()
    self:HighlightRuins()
end

function repair_all_map_cat_picker_tool:OnActivateSelectorRequest()

    if ( self.selectedMode >= self.modeSelectLast ) then

        if ( self:ChangeSelector(self.lastSelectedCategory) ) then

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

        local buildingDescRef = reflection_helper(buildingDesc)
        if ( buildingDescRef.category == nil or buildingDescRef.category == "" ) then
            goto continue
        end

        if ( self:ChangeSelector(buildingDescRef.category) ) then

            return
        end

        ::continue::
    end
end

function repair_all_map_cat_picker_tool:ChangeSelector(category)

    if ( category == "" or category == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.category_name, category )

    self.selectedCategory = category

    self:AddCategoryToLastList(category, self.selector)

    self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

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

function repair_all_map_cat_picker_tool:FillLastCategoriesList(defaultModesArray, modeSelectLast, selector)

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

function repair_all_map_cat_picker_tool:AddCategoryToLastList(category, selector)

    LastSelectedBlueprintsListUtils:AddStringToList(self.list_name, selector, category)
end

function repair_all_map_cat_picker_tool:OnRotateSelectorRequest(evt)

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

function repair_all_map_cat_picker_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function repair_all_map_cat_picker_tool:HighlightRuins()

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

function repair_all_map_cat_picker_tool:FindBuildingRuins()

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

function repair_all_map_cat_picker_tool:OnRelease()

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do

            self:RemovedFromSelection( ruinEntity )
        end
    end
    self.previousMarkedRuins = {}

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return repair_all_map_cat_picker_tool
 