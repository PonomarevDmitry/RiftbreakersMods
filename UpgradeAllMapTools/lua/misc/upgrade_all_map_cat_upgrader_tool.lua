local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/upgrade_all_map_tools_last_selected_blueprints_utils.lua")

class 'upgrade_all_map_cat_upgrader_tool' ( tool )

function upgrade_all_map_cat_upgrader_tool:__init()
    tool.__init(self,self)
end

function upgrade_all_map_cat_upgrader_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function upgrade_all_map_cat_upgrader_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.categoryTemplate = self.data:GetStringOrDefault("category_name", "") or ""

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.selectedCategory = ""

    self.modeSelect = 0
    self.modeSelectLast = 100

    if ( self.categoryTemplate ~= "" ) then

        local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

        self.selectedCategory = selectorDB:GetStringOrDefault( self.categoryTemplate, "" ) or ""

        self.defaultModesArray = { self.modeSelect }

        self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)
    end

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function upgrade_all_map_cat_upgrader_tool:UpdateMarker()

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

        messageText = "${gui/hud/upgrade_all_map/last_building} " .. tostring(indexCategory + 1)

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

        messageText = "${gui/hud/upgrade_all_map/building_category_not_selected}"
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

function upgrade_all_map_cat_upgrader_tool:GetBuildinsDescription()

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

function upgrade_all_map_cat_upgrader_tool:GetIconsData()

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

function upgrade_all_map_cat_upgrader_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function upgrade_all_map_cat_upgrader_tool:AddedToSelection( entity )

    self:CreateMarkEntity(entity)
end

function upgrade_all_map_cat_upgrader_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function upgrade_all_map_cat_upgrader_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end

    self:RemoveMarkEntity(entity)
end

function upgrade_all_map_cat_upgrader_tool:OnUpdate()

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

function upgrade_all_map_cat_upgrader_tool:GetMenuIcon( blueprintName )

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

function upgrade_all_map_cat_upgrader_tool:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    self.cacheBlueprintsMenuIcons = self.cacheBlueprintsMenuIcons or {}

    if ( self.cacheBlueprintsMenuIcons[blueprintName] == nil ) then

        self.cacheBlueprintsMenuIcons[blueprintName] = self:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )
    end

    return self.cacheBlueprintsMenuIcons[blueprintName]
end

function upgrade_all_map_cat_upgrader_tool:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )

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
                    goto labelContinue
                end

                local connectBuildingDesc = BuildingService:GetBuildingDesc( connectBlueprintName )
                if ( connectBuildingDesc == nil ) then
                    goto labelContinue
                end

                local connectBuildingDescRef = reflection_helper( connectBuildingDesc )
                if ( connectBuildingDescRef == nil ) then
                    goto labelContinue
                end

                local menuIcon = connectBuildingDescRef.menu_icon or ""

                if ( menuIcon ~= "" ) then
                    return menuIcon
                end
            end

            ::labelContinue::
        end
    end

    return ""
end

function upgrade_all_map_cat_upgrader_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode >= self.modeSelectLast ) then
        return result
    end

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto labelContinue
        end

        local buildingComponent = EntityService:GetComponent(entity, "BuildingComponent")
        if ( buildingComponent == nil ) then

            if not ( is_server and is_client ) then

                local mapperName = "ForceNetReplicateNextFrameRequest"

                QueueEvent("OperateActionMapperRequest", entity, mapperName, false )
            end

            goto labelContinue
        end

        local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
        if ( mode ~= BM_COMPLETED ) then
            goto labelContinue
        end

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto labelContinue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto labelContinue
        end

        if ( self.categoryTemplate ~= "" ) then

            if ( buildingDescRef.category ~= self.selectedCategory ) then

                goto labelContinue
            end
        end

        if ( not BuildingService:CanUpgrade( entity, self.playerId ) ) then
            goto labelContinue
        end

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

                                    goto labelContinue
                                end
                            end
                        end
                    end
                end
            end
        end

        Insert( result, entity )

        ::labelContinue::
    end

    return result
end

function upgrade_all_map_cat_upgrader_tool:OnActivateSelectorRequest()

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

function upgrade_all_map_cat_upgrader_tool:ChangeSelector(category)

    if ( category == "" or category == nil ) then
        return false
    end

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    selectorDB:SetString( self.categoryTemplate, category )

    self.selectedCategory = category

    self:AddCategoryToLastList(category, self.selector)

    self.modeValuesArray = self:FillLastCategoriesList(self.defaultModesArray, self.modeSelectLast, self.selector)

    self.selectedMode = self.modeSelect

    self:UpdateMarker()

    return true
end

function upgrade_all_map_cat_upgrader_tool:FillLastCategoriesList(defaultModesArray, modeSelectLast, selector)

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

function upgrade_all_map_cat_upgrader_tool:AddCategoryToLastList(category, selector)

    LastSelectedBlueprintsListUtils:AddStringToList(self.list_name, selector, category)
end

function upgrade_all_map_cat_upgrader_tool:OnRotateSelectorRequest(evt)

    if ( self.categoryTemplate == "" ) then
        return
    end

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

function upgrade_all_map_cat_upgrader_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function upgrade_all_map_cat_upgrader_tool:CreateMarkEntity( building )

    local blueprintName = EntityService:GetBlueprintName( building )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

    local buildingDescRef = reflection_helper( buildingDesc )

    if ( buildingDescRef.limit_name == "hq" ) then
        return
    end

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

function upgrade_all_map_cat_upgrader_tool:RemoveMarkEntity( building )

    local markerBlueprintName = "misc/marked_building_to_upgrade_minimap_icon"

    local childreen = EntityService:GetChildren(building, true)

    for entity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName == markerBlueprintName ) then

            EntityService:RemoveEntity( entity )
        end
    end
end

function upgrade_all_map_cat_upgrader_tool:OnRelease()

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

return upgrade_all_map_cat_upgrader_tool