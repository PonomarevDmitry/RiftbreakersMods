local repair_all_map_base = require("lua/misc/repair_all_map_base.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/repair_all_map_tools_last_selected_blueprints_utils.lua")

class 'repair_all_map_repairer_tool' ( repair_all_map_base )

function repair_all_map_repairer_tool:__init()
    repair_all_map_base.__init(self,self)
end

function repair_all_map_repairer_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function repair_all_map_repairer_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self:InitLowUpgradeList()

    self:SetTypeSetting()

    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    self.modeBuilding = 0
    self.modeBuildingGroup = 1
    self.modeBuildingLastSelected = 100

    self.defaultModesArray = { self.modeBuilding, self.modeBuildingGroup }

    self.modeValuesArray = self:FillLastBuildingsList(self.defaultModesArray, self.modeBuildingLastSelected, self.selector)

    self.selectedMode = self.modeBuilding

    self:SetBuildingIcon()

    self.infoChild = EntityService:SpawnAndAttachEntity( "misc/marker_selector/building_info", self.selector )
    EntityService:SetPosition( self.infoChild, -2, 0, 2 )
end

function repair_all_map_repairer_tool:SetBuildingIcon()

    local messageText = ""
    local buildingIconVisible = 0
    local buildingIcon = ""

    local markerBlueprint = self.data:GetString("marker_name")

    if ( self.selectedMode == self.modeBuilding ) then

        markerBlueprint = self.data:GetString("marker_name")

    elseif ( self.selectedMode == self.modeBuildingGroup ) then

        markerBlueprint = self.data:GetString("marker_group")
    end

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

            messageText = "${gui/hud/repair_all_map/last_building} " .. tostring(indexBuilding + 1) .. ":\n${" .. buildingDescRef.localization_id .. "}"
        end

    elseif ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local menuIcon, buildingDescRef = self:GetMenuIcon( self.selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            buildingIcon = menuIcon
            buildingIconVisible = 1

            messageText = "${" .. buildingDescRef.localization_id .. "}"

            if ( self.selectedMode == self.modeBuildingGroup ) then

                messageText = "${gui/hud/repair_all_map/building_group}: " .. messageText
            end
        else

            buildingIcon = "gui/menu/research/icons/missing_icon_big"
            buildingIconVisible = 1

            messageText = "${gui/hud/repair_all_map/building_not_selected}"

            if ( self.selectedMode == self.modeBuildingGroup ) then

                messageText = "${gui/hud/repair_all_map/building_group}: " .. messageText
            end
        end
    else

        buildingIconVisible = 1

        buildingIcon = "gui/menu/research/icons/missing_icon_big"
        messageText = "${gui/hud/repair_all_map/building_not_selected}"

        if ( self.selectedMode == self.modeBuildingGroup ) then

            messageText = "${gui/hud/repair_all_map/building_group}: " .. messageText
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

function repair_all_map_repairer_tool:SetTypeSetting()

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

function repair_all_map_repairer_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function repair_all_map_repairer_tool:AddedToSelection( entity )
end

function repair_all_map_repairer_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function repair_all_map_repairer_tool:OnUpdate()

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

function repair_all_map_repairer_tool:FindEntitiesToSelect( selectorComponent )

    local result = {}

    if ( self.selectedMode >= self.modeBuildingLastSelected ) then
        return {}
    end

    local entitiesBuildings = self:FindRepairableBuildings()

    ConcatUnique( result, entitiesBuildings )

    local ruins = self:FindRuins()

    ConcatUnique( result, ruins )

    return result
end

function repair_all_map_repairer_tool:FindRepairableBuildings()

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

function repair_all_map_repairer_tool:FindRuins()

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

function repair_all_map_repairer_tool:IsEntityApproved( entity )

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

function repair_all_map_repairer_tool:IsBlueprintApproved( blueprintName )

    if ( blueprintName == "" ) then
        return false
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    local isGroup = (self.selectedMode == self.modeBuildingGroup)

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

function repair_all_map_repairer_tool:OnRotateSelectorRequest(evt)

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

function repair_all_map_repairer_tool:CheckModeValueExists( selectedMode )

    selectedMode = selectedMode or self.modeValuesArray[1]

    local index = IndexOf(self.modeValuesArray, selectedMode )

    if ( index == nil ) then

        return self.modeValuesArray[1]
    end

    return selectedMode
end

function repair_all_map_repairer_tool:OnActivateSelectorRequest()

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

function repair_all_map_repairer_tool:ChangeSelector(blueprintName)

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

    self:SetBuildingIcon()

    return true
end

function repair_all_map_repairer_tool:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

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

function repair_all_map_repairer_tool:AddBlueprintToLastList(blueprintName, selector)

    LastSelectedBlueprintsListUtils:AddBlueprintToList(self.list_name, selector, blueprintName)
end

function repair_all_map_repairer_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.infoChild ~= nil) then
        EntityService:RemoveEntity(self.infoChild)
        self.infoChild = nil
    end

    if ( repair_all_map_base.OnRelease ) then
        repair_all_map_base.OnRelease(self)
    end
end

return repair_all_map_repairer_tool