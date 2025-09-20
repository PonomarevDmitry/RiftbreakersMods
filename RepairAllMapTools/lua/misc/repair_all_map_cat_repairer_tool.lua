local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/repair_all_map_tools_last_selected_blueprints_utils.lua")

class 'repair_all_map_cat_repairer_tool' ( tool )

function repair_all_map_cat_repairer_tool:__init()
    tool.__init(self,self)
end

function repair_all_map_cat_repairer_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_cat_repairer_tool:OnInit()

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

function repair_all_map_cat_repairer_tool:UpdateMarker()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.categoryTemplate == "" ) then

        messageText = ""

    elseif ( self.selectedMode >= self.modeSelectLast ) then

        markerBlueprint = self.data:GetString("marker_select")

        local indexCategory = self.selectedMode - self.modeSelectLast

        local categoryNumber = #self.lastSelectedCategoriesArray - indexCategory

        self.lastSelectedCategory = self.lastSelectedCategoriesArray[categoryNumber]


        local menuIcon = "gui/hud/building_icons/" .. self.lastSelectedCategory ..  "_structures_neutral"

        messageText = "${gui/hud/repair_all_map/last_building} " .. tostring(indexCategory + 1)

        buildingIcon = menuIcon
        buildingIconVisible = 1

    elseif ( self.selectedCategory ~= "" ) then

        messageText = ""

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

        messageText = "${gui/hud/repair_all_map/building_category_not_selected}"
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

function repair_all_map_cat_repairer_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool_green", self.entity )
    end
end

function repair_all_map_cat_repairer_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_cat_repairer_tool:AddedToSelection( entity )
end

function repair_all_map_cat_repairer_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) and not EntityService:HasComponent( child, "EffectReferenceComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function repair_all_map_cat_repairer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function repair_all_map_cat_repairer_tool:OnUpdate()

    self.repairCosts = {}

    local repairCostsEntities = {}

    for entity in Iter( self.selectedEntities ) do

        if ( repairCostsEntities[entity] ~= nil ) then
            goto continue
        end

        repairCostsEntities[entity] = true


        local isRuins = ( EntityService:GetGroup( entity ) == "##ruins##" )

        if ( not isRuins ) then

            if ( not BuildingService:IsBuildingFinished( entity ) ) then
                goto continue
            end
        end

        local blueprintName = self:GetBlueprintName( entity )
        if ( blueprintName == "" ) then
            goto continue
        end

        self:SetEntitySelectedMaterial( entity, "hologram/pass" )

        local list = {}

        if ( isRuins ) then

            local database = EntityService:GetOrCreateDatabase( entity )
            if ( database ) then

                local ruinsBlueprint = database:GetString("blueprint")

                list = BuildingService:GetBuildCosts( ruinsBlueprint, self.playerId )
            end
        else

            list = BuildingService:GetRepairCosts( entity )
        end

        for resourceCost in Iter(list) do

            if ( self.repairCosts[resourceCost.first] == nil ) then
                self.repairCosts[resourceCost.first] = 0
            end

            self.repairCosts[resourceCost.first] = self.repairCosts[resourceCost.first] + resourceCost.second
        end

        ::continue::
    end

    local onScreen = CameraService:IsOnScreen( self.infoChild, 1 )
    if ( onScreen ) then
        BuildingService:OperateRepairCosts( self.infoChild, self.playerId, self.repairCosts )
        BuildingService:OperateRepairCosts( self.corners, self.playerId, {} )
    else
        BuildingService:OperateRepairCosts( self.infoChild, self.playerId, {} )
        BuildingService:OperateRepairCosts( self.corners, self.playerId, self.repairCosts )
    end
end

function repair_all_map_cat_repairer_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode ~= self.modeSelect ) then
        return result
    end

    local entitiesBuildings = self:FindRepairableBuildings()

    ConcatUnique( result, entitiesBuildings )

    local ruins = self:FindRuins()

    ConcatUnique( result, ruins )

    return result
end

function repair_all_map_cat_repairer_tool:FindRepairableBuildings()

    local result = {}

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity) ) then
            goto continue
        end

        local healthComponent = EntityService:GetComponent(entity, "HealthComponent")
        if ( healthComponent == nil ) then
            goto continue
        end

        local childRepair = EntityService:GetChildByName( entity, "##repair##" )

        if ( childRepair ~= INVALID_ID and EntityService:IsAlive(childRepair) ) then
            goto continue
        end

        local healthComponentRef = reflection_helper(healthComponent)

        if ( healthComponentRef.health < healthComponentRef.max_health ) then
            Insert( result, entity )
            goto continue
        end

        local database = EntityService:GetOrCreateDatabase( entity )
        if ( database and database:HasInt("number_of_activations")) then

            local currentNumberOfActivations =  database:GetInt("number_of_activations")

            local blueprintDatabase = EntityService:GetBlueprintDatabase( entity )
            local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")

            if ( maxNumberOfActivations > currentNumberOfActivations ) then
                Insert( result, entity )
            end
        end

        ::continue::
    end

    return result
end

function repair_all_map_cat_repairer_tool:FindRuins()

    local result = {}

    local ruins = FindService:FindEntitiesByGroup( "##ruins##" )

    for entity in Iter( ruins ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetOrCreateDatabase( entity )
        if ( not database ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local blueprintName = database:GetString("blueprint")
        if ( blueprintName == "" ) then
            goto continue
        end

        if ( not self:IsBlueprintApproved(blueprintName) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    return result
end

function repair_all_map_cat_repairer_tool:IsEntityApproved( entity )

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
    if ( mode ~= BM_COMPLETED ) then
        return false
    end

    if ( not EntityService:HasComponent( entity, "SelectableComponent" ) ) then
        return false
    end

    local blueprintName = self:GetBlueprintName(entity)
    if ( blueprintName == "" ) then
        return false
    end

    if ( self:IsBlueprintApproved( blueprintName ) ) then
        return true
    end

    return false
end

function repair_all_map_cat_repairer_tool:IsBlueprintApproved( blueprintName )

    if ( blueprintName == "" ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    if ( self.categoryTemplate == "" ) then
        return true
    end

    local buildingDescRef = reflection_helper( buildingDesc )

    if ( buildingDescRef.category == self.selectedCategory ) then

        return true
    end

    return false
end

function repair_all_map_cat_repairer_tool:OnActivateSelectorRequest()

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

        if ( EntityService:GetGroup( entity ) == "##ruins##" ) then

            local database = EntityService:GetOrCreateDatabase( entity )
            if ( database ) then

                local ruinsBlueprint = database:GetString("blueprint")

                local transform = EntityService:GetWorldTransform( entity )

                QueueEvent( "BuildBuildingRequest", INVALID_ID, self.playerId, ruinsBlueprint, transform, true, database )
            end
        else
            local childRepair = EntityService:GetChildByName(entity, "##repair##")

            if ( BuildingService:CanAffordRepair( entity, self.playerId, -1 ) and not EntityService:IsAlive(childRepair) ) then

                local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
                if ( buildingComponent ~= nil ) then

                    local mode = tonumber( buildingComponent:GetField("mode"):GetValue() )
                    if ( mode ~= BM_COMPLETED ) then
                        return
                    end
                end

                QueueEvent( "ScheduleRepairBuildingRequest", entity, self.playerId )
            end
        end
    end
end

function repair_all_map_cat_repairer_tool:ChangeSelector(category)

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

function repair_all_map_cat_repairer_tool:GetBlueprintName( entity )

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

function repair_all_map_cat_repairer_tool:FillLastCategoriesList(defaultModesArray, modeSelectLast, selector)

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

function repair_all_map_cat_repairer_tool:AddCategoryToLastList(category, selector)

    LastSelectedBlueprintsListUtils:AddStringToList(self.list_name, selector, category)
end

function repair_all_map_cat_repairer_tool:OnRotateSelectorRequest(evt)

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

function repair_all_map_cat_repairer_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function repair_all_map_cat_repairer_tool:OnRelease()

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

return repair_all_map_cat_repairer_tool