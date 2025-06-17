local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_base' ( tool )

function sell_by_type_base:__init()
    tool.__init(self,self)
end

function sell_by_type_base:InitLowUpgradeList()

    self.template_name = self.data:GetString("template_name")
    self.list_name = self.data:GetStringOrDefault("list_name", "") or ""

    local selectorDB = EntityService:GetOrCreateDatabase( self.selector )

    self.selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.selectedBlueprints = {}

    self.selectedLowUpgrade = {}

    if ( self.selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", self.selectedBuildingBlueprint ) ) then

        local blueprintName = self:GetFirstLevelBuilding(self.selectedBuildingBlueprint)

        self:FillSelectedBlueprintsList(self.selectedBlueprints, self.selectedBuildingBlueprint)

        self:FillLowUpgradeList(self.selectedLowUpgrade, self.selectedBuildingBlueprint)

        self:FillCache()
    end
end

function sell_by_type_base:GetFirstLevelBuilding(blueprintName)

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

function sell_by_type_base:FillCache()

    self.cacheBlueprintsLowNames = {}

    self.cacheBlueprints = {}

    for blueprintName in Iter( self.selectedBlueprints ) do

        self.cacheBlueprints[blueprintName] = true
    end
end

function sell_by_type_base:FillLowUpgradeList( list, blueprintName, seenBlueprintList )

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

function sell_by_type_base:AddToLowUpgradeList( list, buildingDescRef )

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

function sell_by_type_base:FillSelectedBlueprintsList( list, blueprintName, seenBlueprintList )

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

function sell_by_type_base:AddToSelectedBlueprintsList( list, buildingDescRef )

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

function sell_by_type_base:IsBlueprintInList( blueprintName )

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

function sell_by_type_base:CalcIsBlueprintInList( blueprintName )

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

function sell_by_type_base:IsBlueprintInLowNameList( blueprintName )

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

function sell_by_type_base:CalcIsBlueprintInLowNameList( blueprintName )

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

function sell_by_type_base:GetMenuIcon( blueprintName )

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon, buildingDescRef
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon, baseBuildingDescRef
        end
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            local connectMenuIcon, connectBuildingDescRef = self:GetBuildingMenuIcon( connectBlueprintName )

            if ( connectMenuIcon ~= "" ) then

                return connectMenuIcon, connectBuildingDescRef
            end
        end
    end

    return ""
end

function sell_by_type_base:GetBuildingMenuIcon( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( buildingDesc == nil ) then
        return ""
    end

    local buildingDescRef = reflection_helper( buildingDesc )
    if ( buildingDescRef == nil ) then
        return ""
    end

    local menuIcon = buildingDescRef.menu_icon or ""
    if ( menuIcon ~= "" ) then
        return menuIcon, buildingDescRef
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon, baseBuildingDescRef
        end
    end

    return ""
end

return sell_by_type_base
 