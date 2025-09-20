local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/sell_all_map_tools_last_selected_blueprints_utils.lua")

class 'sell_all_map_cat_seller_tool' ( tool )

function sell_all_map_cat_seller_tool:__init()
    tool.__init(self,self)
end

function sell_all_map_cat_seller_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_all_map_cat_seller_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.categoryTemplate = self.data:GetStringOrDefault("category_name", "") or ""

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.selectedCategory = ""

    self.categoryNotSelected = false

    self.modeSelect = 0
    self.modeSelectRuins = 1
    self.modeBuildingConnectors = 2

    self.modeSelectLast = 100

    if ( self.categoryTemplate ~= "" ) then

        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

        self.selectedCategory = selectorDB:GetStringOrDefault( self.categoryTemplate, "" ) or ""

        self.defaultModesArray = {

            self.modeSelect,
            self.modeSelectRuins,
            --self.modeBuildingConnectors,
        }

        self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)
    else
        self.modeValuesArray = {
            self.modeSelect,
            self.modeSelectRuins,
            --self.modeBuildingConnectors,
        }
    end

    self.selectedMode = self.modeSelect

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function sell_all_map_cat_seller_tool:GetBaseEntitiesList()

    local result = {}
    local hashResult = {}

    if ( self.selectedMode >= self.modeSelectLast ) then
        return result
    end

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( hashResult[entity] == true ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto continue
        end

        local buildingComponentRef = reflection_helper(buildingComponent)
        if ( buildingComponentRef.m_isSellable == false ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
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
        if ( lowName == "energy_connector" ) then
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

function sell_all_map_cat_seller_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity( "misc/marker_selector_corner_tool_gold", self.entity )
    end
end

function sell_all_map_cat_seller_tool:UpdateMarker()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.categoryTemplate == "" ) then

        messageText = self:GetBuildinsDescription()

    elseif ( self.selectedMode >= self.modeSelectLast ) then

        markerBlueprint = self.data:GetString("marker_select")

        local indexCategory = self.selectedMode - self.modeSelectLast

        local categoryNumber = #self.lastSelectedCategoriesArray - indexCategory

        self.lastSelectedCategory = self.lastSelectedCategoriesArray[categoryNumber]


        local menuIcon = "gui/hud/building_icons/" .. self.lastSelectedCategory ..  "_structures_neutral"

        messageText = "${gui/hud/sell_all_map/last_building} " .. tostring(indexCategory + 1)

        buildingIcon = menuIcon
        buildingIconVisible = 1

    elseif ( self.selectedCategory ~= "" ) then

        messageText = self:GetBuildinsDescription()

        local menuIcon = "gui/hud/building_icons/" .. self.selectedCategory ..  "_structures_neutral"

        if ( ResourceManager:ResourceExists("Material", menuIcon) ) then

            buildingIcon = menuIcon
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
        end

        buildingIconVisible = 1
    else

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        buildingIconVisible = 1

        messageText = "${gui/hud/sell_all_map/building_category_not_selected}"
    end

    if ( self.selectedMode == self.modeSelectRuins ) then

        markerBlueprint = self.data:GetString("marker_place_ruins")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/sell_all_map/place_ruins}\n" .. messageText
        else

            messageText = "${gui/hud/sell_all_map/place_ruins}"
        end

    elseif ( self.selectedMode == self.modeBuildingConnectors ) then

        markerBlueprint = self.data:GetString("marker_place_connectors")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/sell_all_map/place_connectors}\n" .. messageText
        else

            messageText = "${gui/hud/sell_all_map/place_connectors}"
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

function sell_all_map_cat_seller_tool:GetBuildinsDescription()

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

function sell_all_map_cat_seller_tool:GetIconsData()

    self.selectedEntities = self.selectedEntities or {}

    local sellCostsEntities = {}

    local listIconsNames = {}
    local hashIconsCount = {}

    for entity in Iter( self.selectedEntities ) do

        if ( sellCostsEntities[entity] ~= nil ) then
            goto continue
        end

        sellCostsEntities[entity] = true

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )
        if ( menuIcon ~= "" ) then

            if ( hashIconsCount[menuIcon] == nil ) then

                Insert( listIconsNames, menuIcon )

                hashIconsCount[menuIcon] = 0
            end

            hashIconsCount[menuIcon] = hashIconsCount[menuIcon] + 1
        end

        ::continue::
    end

    return listIconsNames,hashIconsCount
end

function sell_all_map_cat_seller_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_all_map_cat_seller_tool:AddedToSelection( entity )
end

function sell_all_map_cat_seller_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function sell_all_map_cat_seller_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function sell_all_map_cat_seller_tool:OnUpdate()

    self:UpdateMarker()

    self.sellCosts = {}

    local sellCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( sellCostsEntities[entity] ~= nil ) then
            goto continue
        end

        sellCostsEntities[entity] = true



        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( EntityService:HasComponent(entity, "IsVisibleComponent") ) then

            self:SetEntitySelectedMaterial( entity, "hologram/active" )
        end

        local list = BuildingService:GetSellResourceAmount( entity )
        for resourceCost in Iter(list) do

            if ( self.sellCosts[resourceCost.first] == nil ) then
                self.sellCosts[resourceCost.first] = 0
            end

            self.sellCosts[resourceCost.first] = self.sellCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end



    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, self.sellCosts )
        BuildingService:OperateSellCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateSellCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateSellCosts( self.corners, self.playerId, self.sellCosts )
    end
end

function sell_all_map_cat_seller_tool:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    return menuIcon
end

function sell_all_map_cat_seller_tool:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    self.cacheBlueprintsMenuIcons = self.cacheBlueprintsMenuIcons or {}

    if ( self.cacheBlueprintsMenuIcons[blueprintName] == nil ) then

        self.cacheBlueprintsMenuIcons[blueprintName] = self:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )
    end

    return self.cacheBlueprintsMenuIcons[blueprintName]
end

function sell_all_map_cat_seller_tool:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )

    local menuIcon = ""

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""

        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end


    menuIcon = buildingDescRef.menu_icon or ""

    if ( menuIcon ~= "" ) then
        return menuIcon
    end

    if ( buildingDescRef.connect.count > 0 ) then

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                if ( not ResourceManager:ResourceExists( "EntityBlueprint", connectBlueprintName ) ) then
                    goto continue
                end

                local connectBuildingDesc = BuildingService:GetBuildingDesc( connectBlueprintName )
                if ( connectBuildingDesc == nil ) then
                    goto continue
                end

                local connectBuildingDescRef = reflection_helper( connectBuildingDesc )
                if ( connectBuildingDescRef == nil ) then
                    goto continue
                end

                local menuIcon = connectBuildingDescRef.menu_icon or ""

                if ( menuIcon ~= "" ) then
                    return menuIcon
                end
            end

            ::continue::
        end
    end

    return ""
end

function sell_all_map_cat_seller_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}
    local hashResult = {}

    if ( self.selectedMode >= self.modeSelectLast ) then
        return result
    end

    local entitiesBuildings = self.entitiesBuildings or {}

    for entity in Iter( entitiesBuildings ) do

        if ( not EntityService:IsAlive(entity) ) then
            goto continue
        end

        if ( hashResult[entity] == true ) then
            goto continue
        end

        local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
        if ( buildingComponent == nil ) then
            goto continue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode >= BM_SELLING ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function sell_all_map_cat_seller_tool:OnActivateSelectorRequest()

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

    local placeRuins = ( self.selectedMode == self.modeSelectRuins )

    local placeConnectors = ( self.selectedMode == self.modeBuildingConnectors )

    for entity in Iter( self.selectedEntities ) do

        if ( placeRuins ) then

            local blueprintName = EntityService:GetBlueprintName( entity )

            local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
            if ( buildingDesc ~= nil ) then

                local buildingDescRef = reflection_helper( buildingDesc )
                if ( buildingDescRef ~= nil and buildingDescRef.build_cost ~= nil and buildingDescRef.build_cost.resource ~= nil and buildingDescRef.build_cost.resource.count ~= nil and buildingDescRef.build_cost.resource.count > 0 ) then

                    local ruinsBlueprintName = blueprintName .. "_ruins"

                    if ( ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprintName ) ) then

                        local mapperName = "SellAndPlaceRuinsRequest|" .. tostring(self.playerId)

                        QueueEvent("OperateActionMapperRequest", entity, mapperName, false )

                        return
                    end
                end
            end
        end

        if ( placeConnectors ) then

            local team = EntityService:GetTeam( entity )

            local transform = EntityService:GetWorldTransform( entity )

            local position = transform.position
            local orientation = transform.orientation

            local buildAfterSellScript = EntityService:SpawnEntity( "buildings/tools/sell_all_map_seller_tool/script", position, team )

            local database = EntityService:GetOrCreateDatabase( buildAfterSellScript )

            database:SetInt( "target_entity", entity )
            database:SetInt( "player_id", self.playerId )

            database:SetString( "building_blueprintname", "buildings/energy/energy_connector" )
        end

        QueueEvent( "SellBuildingRequest", entity, self.playerId, false )
    end
end

function sell_all_map_cat_seller_tool:ChangeSelector(category)

    if ( category == "" or category == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.categoryTemplate, category )

    self.selectedCategory = category

    self:AddCategoryToLastList(category, self.selector)

    self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    return true
end

function sell_all_map_cat_seller_tool:FillLastCategoriesList(defaultModesArray, modeSelectLast, selector)

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

function sell_all_map_cat_seller_tool:AddCategoryToLastList(category, selector)

    LastSelectedBlueprintsListUtils:AddStringToList(self.list_name, selector, category)
end

function sell_all_map_cat_seller_tool:OnRotateSelectorRequest(evt)

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

function sell_all_map_cat_seller_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function sell_all_map_cat_seller_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return sell_all_map_cat_seller_tool