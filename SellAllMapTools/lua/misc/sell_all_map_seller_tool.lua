local sell_all_map_base = require("lua/misc/sell_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/sell_all_map_tools_last_selected_blueprints_utils.lua")

class 'sell_all_map_seller_tool' ( sell_all_map_base )

function sell_all_map_seller_tool:__init()
    sell_all_map_base.__init(self,self)
end

function sell_all_map_seller_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function sell_all_map_seller_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.modeBuilding = 0
    self.modeBuildingRuins = 1
    self.modeBuildingConnectors = 2


    self.modeBuildingGroup = 3
    self.modeBuildingGroupRuins = 4
    self.modeBuildingGroupConnectors = 5

    self.modeBuildingLastSelected = 100

    self.defaultModesArray = {
        self.modeBuilding,
        self.modeBuildingRuins,

        self.modeBuildingGroup,
        self.modeBuildingGroupRuins
    }

    --if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) and self.selectedBuildingBlueprint ~= "buildings/energy/energy_connector" ) then
    --
    --    self.defaultModesArray = {
    --        self.modeBuilding,
    --        self.modeBuildingRuins,
    --        self.modeBuildingConnectors,
    --
    --        self.modeBuildingGroup,
    --        self.modeBuildingGroupRuins,
    --        self.modeBuildingGroupConnectors,
    --    }
    --end

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function sell_all_map_seller_tool:GetBaseEntitiesList()

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

        if ( not EntityService:IsAlive(entity) ) then
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

function sell_all_map_seller_tool:UpdateMarker()

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

            messageText = "${gui/hud/sell_all_map/last_building} " .. tostring(indexBuilding + 1) .. "\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = self:GetBuildinsDescription()
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
            buildingIconVisible = 1

            messageText = "${gui/hud/sell_all_map/building_not_selected}"
        end
    else

        buildingIconVisible = 1

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        messageText = "${gui/hud/sell_all_map/building_not_selected}"
    end

    if ( self.selectedMode == self.modeBuildingRuins ) then

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

    elseif ( self.selectedMode == self.modeBuildingGroup ) then

        markerBlueprint = self.data:GetString("marker_group")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/sell_all_map/building_group}\n" .. messageText
        else

            messageText = "${gui/hud/sell_all_map/building_group}"
        end

    elseif ( self.selectedMode == self.modeBuildingGroupRuins ) then

        markerBlueprint = self.data:GetString("marker_place_ruins_group")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/sell_all_map/place_ruins}\n${gui/hud/sell_all_map/building_group}\n" .. messageText
        else

            messageText = "${gui/hud/sell_all_map/place_ruins}\n${gui/hud/sell_all_map/building_group}"
        end

    elseif ( self.selectedMode == self.modeBuildingGroupConnectors ) then

        markerBlueprint = self.data:GetString("marker_place_connectors_group")

        if (string.len(messageText) > 0) then

            messageText = "${gui/hud/sell_all_map/place_connectors}\n${gui/hud/sell_all_map/building_group}\n" .. messageText
        else

            messageText = "${gui/hud/sell_all_map/place_connectors}\n${gui/hud/sell_all_map/building_group}"
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

function sell_all_map_seller_tool:GetBuildinsDescription()

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

function sell_all_map_seller_tool:GetIconsData()

    self.selectedEntities = self.selectedEntities or {}

    local sellCostsEntities = {}

    local listIconsNames = {}
    local hashIconsCount = {}

    for entity in Iter( self.selectedEntities ) do

        if ( sellCostsEntities[entity] ~= nil ) then
            goto continue
        end

        sellCostsEntities[entity] = true

        if ( not BuildingService:IsBuildingFinished( entity ) ) then
            goto continue
        end

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


function sell_all_map_seller_tool:SetTypeSetting()

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

function sell_all_map_seller_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function sell_all_map_seller_tool:AddedToSelection( entity )
end

function sell_all_map_seller_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function sell_all_map_seller_tool:OnUpdate()

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

function sell_all_map_seller_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return result
    end

    local hashResult = {}

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
        hashResult[entity] = true

        ::continue::
    end

    return result
end

function sell_all_map_seller_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode >= BM_SELLING ) then
        return false
    end

    local buildingComponentRef = reflection_helper(buildingComponent)
    if ( buildingComponentRef.m_isSellable == false ) then
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

    local isGroup = (self.selectedMode == self.modeBuildingGroup or self.selectedMode == self.modeBuildingGroupRuins or self.selectedMode == self.modeBuildingGroupConnectors)

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

function sell_all_map_seller_tool:OnRotateSelectorRequest(evt)

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

function sell_all_map_seller_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function sell_all_map_seller_tool:OnActivateSelectorRequest()

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

    local placeRuins = ( self.selectedMode == self.modeBuildingRuins or self.selectedMode == self.modeBuildingGroupRuins )
    local placeConnectors = ( self.selectedMode == self.modeBuildingConnectors or self.selectedMode == self.modeBuildingGroupConnectors )

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

function sell_all_map_seller_tool:ChangeSelector(blueprintName)

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

    self.entitiesBuildings = self:GetBaseEntitiesList()

    self:UpdateMarker()

    return true
end

function sell_all_map_seller_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

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

function sell_all_map_seller_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function sell_all_map_seller_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( sell_all_map_base.OnRelease ) then
        sell_all_map_base.OnRelease(self)
    end
end

return sell_all_map_seller_tool