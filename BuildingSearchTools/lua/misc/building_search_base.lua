require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

local LastSelectedBlueprintsListUtils = require("lua/utils/building_search_tools_last_selected_blueprints_utils.lua")

local tool = require("lua/misc/tool.lua")

class 'building_search_base' ( tool )

function building_search_base:__init()
    tool.__init(self,self)
end

function building_search_base:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function building_search_base:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function building_search_base:InitLowUpgradeList(selectedBuildingBlueprint)

    self.selectedBlueprints = {}

    self.selectedLowUpgrade = {}

    self.cacheBlueprintsLowNames = {}

    self.cacheBlueprints = {}

    self.selectedType = ""

    if ( selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", selectedBuildingBlueprint ) ) then

        local blueprintName = self:GetFirstLevelBuilding(selectedBuildingBlueprint)

        self:FillSelectedBlueprintsList(self.selectedBlueprints, selectedBuildingBlueprint)

        self:FillLowUpgradeList(self.selectedLowUpgrade, selectedBuildingBlueprint)

        self:FillCache()

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc ~= nil ) then

            local buildingDescRef = reflection_helper( buildingDesc )

            if ( buildingDescRef.type ~= nil and buildingDescRef.type ~= "" ) then

                self.selectedType = buildingDescRef.type
            end
        end
    end
end

function building_search_base:GetFirstLevelBuilding(blueprintName)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then

        return blueprintName
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef.level == 1 ) then

        return buildingDescRef.bp
    end

    blueprintName = buildingDescRef.bp

    local suffix = "_lvl_" .. tostring(buildingDescRef.level)

    if ( blueprintName:sub(-#suffix) == suffix ) then

        local result = blueprintName:sub(1,-#suffix-1)

        if ( ResourceManager:ResourceExists( "EntityBlueprint", result )  ) then

            local buildingDesc = BuildingService:GetBuildingDesc( result )
            if ( buildingDesc ~= nil ) then

                return result
            end
        end
    end

    return blueprintName
end

function building_search_base:FillCache()

    for blueprintName in Iter( self.selectedBlueprints ) do

        self.cacheBlueprints[blueprintName] = true
    end
end

function building_search_base:FillLowUpgradeList( list, blueprintName, seenBlueprintList )

    seenBlueprintList = seenBlueprintList or {}

    if ( seenBlueprintList[blueprintName] == true ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then

        local buildingDescRef = reflection_helper( buildingDesc )

        self:AddToLowUpgradeList( list, buildingDescRef )

        seenBlueprintList[blueprintName] = true

        if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

            self:FillLowUpgradeList( list, buildingDescRef.upgrade, seenBlueprintList )
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                self:FillLowUpgradeList( list, connectBlueprintName, seenBlueprintList )
            end
        end
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:FillLowUpgradeList( list, baseBuildingDescRef.bp, seenBlueprintList )
        end
    end
end

function building_search_base:AddToLowUpgradeList( list, buildingDescRef )

    local lowName = BuildingService:FindLowUpgrade( buildingDescRef.bp )

    if ( IndexOf( list, lowName ) == nil ) then
        Insert( list, lowName )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            lowName = BuildingService:FindLowUpgrade( connectBlueprintName )

            if ( IndexOf( list, lowName ) == nil ) then
                Insert( list, lowName )
            end
        end
    end
end

function building_search_base:FillSelectedBlueprintsList( list, blueprintName, seenBlueprintList )

    seenBlueprintList = seenBlueprintList or {}

    if ( seenBlueprintList[blueprintName] == true ) then
        return
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc ~= nil ) then

        local buildingDescRef = reflection_helper( buildingDesc )

        self:AddToSelectedBlueprintsList( list, buildingDescRef )

        seenBlueprintList[blueprintName] = true

        if ( buildingDescRef.upgrade ~= "" and buildingDescRef.upgrade ~= nil ) then

            self:FillSelectedBlueprintsList( list, buildingDescRef.upgrade, seenBlueprintList )
        end

        local buildingDescRef = reflection_helper( buildingDesc )

        for i=1,buildingDescRef.connect.count do

            local connectRecord = buildingDescRef.connect[i]

            for j=1,connectRecord.value.count do

                local connectBlueprintName = connectRecord.value[j]

                self:FillSelectedBlueprintsList( list, connectBlueprintName, seenBlueprintList )
            end
        end
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if (baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper(baseBuildingDesc)

        if ( baseBuildingDescRef.bp ~= blueprintName ) then

            self:FillSelectedBlueprintsList( list, baseBuildingDescRef.bp, seenBlueprintList )
        end
    end
end

function building_search_base:AddToSelectedBlueprintsList( list, buildingDescRef )

    if ( IndexOf( list, buildingDescRef.bp ) == nil ) then

        Insert( list, buildingDescRef.bp )
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            if ( IndexOf( list, connectBlueprintName ) == nil ) then
                Insert( list, connectBlueprintName )
            end
        end
    end
end

function building_search_base:IsBlueprintInList( blueprintName )

    if ( #self.selectedBlueprints == 0 ) then
        return false
    end

    if ( self.cacheBlueprints[blueprintName] ~= nil ) then

        return self.cacheBlueprints[blueprintName]
    end

    local result = self:CalcIsBlueprintInList( blueprintName )

    self.cacheBlueprints[blueprintName] = result

    return result
end

function building_search_base:CalcIsBlueprintInList( blueprintName )

    if ( #self.selectedBlueprints == 0 ) then
        return false
    end

    if ( IndexOf( self.selectedBlueprints, blueprintName ) ~= nil ) then
        return true
    end

    local firstLevelBlueprintName = self:GetFirstLevelBuilding(blueprintName)

    local list = {}

    self:FillSelectedBlueprintsList(list, firstLevelBlueprintName)

    for itemBlueprintName in Iter( list ) do

        if ( IndexOf( self.selectedBlueprints, itemBlueprintName ) ~= nil ) then
            return true
        end
    end

    return false
end

function building_search_base:IsBlueprintInLowNameList( blueprintName )

    if ( #self.selectedLowUpgrade == 0 ) then
        return false
    end

    if ( self.cacheBlueprintsLowNames[blueprintName] ~= nil ) then

        return self.cacheBlueprintsLowNames[blueprintName]
    end

    local result = self:CalcIsBlueprintInLowNameList( blueprintName )

    self.cacheBlueprintsLowNames[blueprintName] = result

    return result
end

function building_search_base:CalcIsBlueprintInLowNameList( blueprintName )

    if ( #self.selectedLowUpgrade == 0 ) then
        return false
    end

    local firstLevelBlueprintName = self:GetFirstLevelBuilding(blueprintName)

    local list = {}

    self:FillLowUpgradeList(list, firstLevelBlueprintName)

    for lowName in Iter( list ) do

        if ( IndexOf( self.selectedLowUpgrade, lowName ) ~= nil ) then
            return true
        end
    end

    return false
end

function building_search_base:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    return menuIcon, buildingDescRef
end

function building_search_base:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    self.cacheBlueprintsMenuIcons = self.cacheBlueprintsMenuIcons or {}

    if ( self.cacheBlueprintsMenuIcons[blueprintName] == nil ) then

        self.cacheBlueprintsMenuIcons[blueprintName] = self:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )
    end

    return self.cacheBlueprintsMenuIcons[blueprintName]
end

function building_search_base:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )

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

function building_search_base:CreateMarkEntity( building )

    local markerBlueprintName = "misc/marked_building_minimap_icon"

    local childreen = EntityService:GetChildren(building, true)

    for entity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName == markerBlueprintName ) then
            return
        end
    end

    local size = EntityService:GetBoundsSize( building )

    local markEntity = EntityService:SpawnAndAttachEntity( markerBlueprintName, building )

    local newPosition = {}

    newPosition.x = 0
    newPosition.y = size.y
    newPosition.z = 0

    EntityService:SetPosition( markEntity, newPosition )
end

function building_search_base:RemoveMarkEntity( building )

    local markerBlueprintName = "misc/marked_building_minimap_icon"

    local childreen = EntityService:GetChildren(building, true)

    for entity in Iter( childreen ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName == markerBlueprintName ) then

            EntityService:RemoveEntity( entity )
        end
    end
end

function building_search_base:RemoveAllMarkers()

    local entities = FindService:FindEntitiesByBlueprint( "misc/marked_building_minimap_icon" )

    for entity in Iter( entities ) do

        EntityService:RemoveEntity( entity )
    end
end

function building_search_base:IsEntityApproved( entity, isGroup )

    isGroup = isGroup or false

    local buildingComponent = EntityService:GetComponent( entity, "BuildingComponent" )
    if ( buildingComponent == nil ) then
        return false
    end

    local blueprintName = EntityService:GetBlueprintName(entity)

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return false
    end

    if ( self:IsBlueprintInList(blueprintName) ) then
        return true
    end

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

function building_search_base:FindEntitiesToMark(blueprintName, isGroup)

    local result = {}

    if ( not blueprintName ) then
        return result
    end

    self:InitLowUpgradeList(blueprintName)

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not self:IsEntityApproved(entity, isGroup) ) then
            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local positions = {}

    for entity in Iter( result ) do
        positions[entity] = EntityService:GetPosition( entity )
    end

    local sorter = function( lh, rh )

        local lhPosition = positions[lh]
        local rhPosition = positions[rh]

        if (lhPosition.x ~= rhPosition.x) then

            return lhPosition.x < rhPosition.x
        end

        return lhPosition.z < rhPosition.z
    end

    table.sort(result, sorter)

    return result
end

function building_search_base:FindEntitiesByCategoryToMark(selectedCategory)

    local result = {}

    if ( not selectedCategory ) then
        return result
    end

    local entitiesBuildings = FindService:FindEntitiesByType( "building" )

    for entity in Iter( entitiesBuildings ) do

        if ( IndexOf( result, entity ) ~= nil ) then
            goto continue
        end

        if ( not EntityService:HasComponent( entity, "BuildingComponent" ) ) then
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

        if ( buildingDescRef.category ~= selectedCategory ) then

            goto continue
        end

        Insert( result, entity )

        ::continue::
    end

    local positions = {}

    for entity in Iter( result ) do
        positions[entity] = EntityService:GetPosition( entity )
    end

    local sorter = function( lh, rh )

        local lhPosition = positions[lh]
        local rhPosition = positions[rh]

        if (lhPosition.x ~= rhPosition.x) then

            return lhPosition.x < rhPosition.x
        end

        return lhPosition.z < rhPosition.z
    end

    table.sort(result, sorter)

    return result
end

function building_search_base:FillLastBuildingsList(defaultModesArray, modeBuildingLastSelected, selector)

    local parameterName = "$last_selected_blueprint"

    self.lastSelectedBuildingsArray = LastSelectedBlueprintsListUtils:GetCurrentList(parameterName, selector)

    local modeValuesArray = Copy(defaultModesArray)

    for index=0,#self.lastSelectedBuildingsArray-1 do

        Insert(modeValuesArray, (modeBuildingLastSelected + index))
    end

    return modeValuesArray
end

function building_search_base:AddBlueprintToLastList(blueprintName, selector)

    local parameterName = "$last_selected_blueprint"

    LastSelectedBlueprintsListUtils:AddBlueprintToList(parameterName, selector, blueprintName)
end

return building_search_base
