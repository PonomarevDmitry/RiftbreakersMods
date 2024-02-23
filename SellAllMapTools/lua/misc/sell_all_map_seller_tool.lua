local sell_all_map_base = require("lua/misc/sell_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

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

    self.isGroup = false
    self.currentChildIsGroup = nil

    self.buildingNoSelected = false

    self:UpdateMarker()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -1, 0, 1 )
end

function sell_all_map_seller_tool:UpdateMarker()

    local messageText = ""
    local groupString = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.isGroup ) then
        messageText = "gui/hud/sell_all_map/building_group"
        groupString = "_by_group"

        markerBlueprint = self.data:GetString("marker_group")
    end

    if ( self.childEntity == nil or self.currentChildIsGroup ~= self.isGroup ) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end


        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        self.currentChildIsGroup = self.isGroup
    end

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetInt("building_visible", 1)

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetString("message_text", messageText)
        else

            markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
            markerDB:SetString("message_text", "gui/hud/sell_all_map/building_not_selected")

            self.buildingNoSelected = true
        end
    else

        markerDB:SetString("building_icon", "gui/menu/research/icons/missing_icon_big")
        markerDB:SetString("message_text", "gui/hud/sell_all_map/building_not_selected")

        self.buildingNoSelected = true
    end
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
end

function sell_all_map_seller_tool:OnUpdate()

    self.sellCosts = {}

    local sellCostsEntities = {}

    local listIconsNames = {}
    local hashIconsCount = {}

    for entity in Iter( self.selectedEntities ) do

        if ( sellCostsEntities[entity] ~= nil ) then
            goto continue
        end

        sellCostsEntities[entity] = true

        local skinned = EntityService:IsSkinned(entity)



        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )

        local buildingDescRef = reflection_helper( buildingDesc )

        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected" )
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected" )
        end

        local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )
        if ( menuIcon ~= "" ) then

            if ( hashIconsCount[menuIcon] == nil ) then

                Insert( listIconsNames, menuIcon )

                hashIconsCount[menuIcon] = 0
            end

            hashIconsCount[menuIcon] = hashIconsCount[menuIcon] + 1
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

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.buildingNoSelected ) then

        markerDB:SetString("message_text", "gui/hud/sell_all_map/building_not_selected")
    else

        local buildingsIcons = ""

        for menuIcon in Iter( listIconsNames ) do

            local count = hashIconsCount[menuIcon]

            if ( count > 0 ) then

                if ( string.len(buildingsIcons) > 0 ) then

                    buildingsIcons = buildingsIcons .. ", "
                end

                buildingsIcons = buildingsIcons .. '<img="' .. menuIcon .. '">x' .. tostring(count)
            end
        end

        local markerText = ""

        if (string.len(buildingsIcons) > 0) then

            if ( self.isGroup ) then
                markerText = "${gui/hud/sell_all_map/building_group}: " .. buildingsIcons
            else
                markerText = buildingsIcons
            end
        else

            if ( self.isGroup ) then
                markerText = "gui/hud/sell_all_map/building_group"
            end
        end

        markerDB:SetString("message_text", markerText)
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

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local distances = {}

    for entity in Iter( result ) do
        distances[entity] = EntityService:GetDistanceBetween( self.entity, entity )
    end

    local sorter = function( lh, rh )
        return distances[lh] < distances[rh]
    end

    table.sort(result, sorter)

    return result
end

function sell_all_map_seller_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
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

    if ( self.isGroup ) then

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

    local currentGroupValue = self:CheckGroupValueExists(self.isGroup)

    local groupValuesArray = self:GetGroupValuesArray()

    local index = IndexOf( groupValuesArray, currentGroupValue )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #groupValuesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex <= 0 ) then
        newIndex = 1
    end

    local newValue = groupValuesArray[newIndex]

    self.isGroup = newValue

    self:UpdateMarker()

    self:OnWorkExecute()
end

function sell_all_map_seller_tool:CheckGroupValueExists( groupValue )

    local groupValuesArray = self:GetGroupValuesArray()

    groupValue = groupValue or groupValuesArray[1]

    local index = IndexOf(groupValuesArray, groupValue )

    if ( index == nil ) then

        return groupValuesArray[1]
    end

    return groupValue
end

function sell_all_map_seller_tool:GetGroupValuesArray()

    if ( self.groupValuesArray == nil ) then

        self.groupValuesArray = { false, true }
    end

    return self.groupValuesArray
end

function sell_all_map_seller_tool:OnActivateSelectorRequest()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do

        QueueEvent( "SellBuildingRequest", entity, self.playerId, false )

        ::continue::
    end
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