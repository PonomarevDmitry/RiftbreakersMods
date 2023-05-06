local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/reflection.lua")

class 'sell_by_type_base' ( tool )

function sell_by_type_base:__init()
    tool.__init(self,self)
end

function sell_by_type_base:InitLowUpgradeList()

    self.template_name = self.data:GetString("template_name")

    local selectorDB = EntityService:GetDatabase( self.selector )

    local selectedBuildingBlueprint = selectorDB:GetStringOrDefault( self.template_name, "" ) or ""

    self.cacheBlueprints = {}

    self.selectedBlueprints = {}

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( selectedBuildingBlueprint ~= "" and ResourceManager:ResourceExists( "EntityBlueprint", selectedBuildingBlueprint ) ) then

        self:FillSelectedBlueprintsList(self.selectedBlueprints, selectedBuildingBlueprint)

        self:FillCache()

        local menuIcon = self:GetMenuIcon( selectedBuildingBlueprint )

        if ( menuIcon ~= "" ) then

            markerDB:SetString("building_icon", menuIcon)
            markerDB:SetInt("building_visible", 1)
        else

            markerDB:SetInt("building_visible", 0)
        end
    else
        markerDB:SetInt("building_visible", 0)
    end
end

function sell_by_type_base:FillCache()

    for blueprintName in Iter( self.selectedBlueprints ) do

        self.cacheBlueprints[blueprintName] = true
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

    local list = {}

    self:FillSelectedBlueprintsList(list, blueprintName)

    for itemBlueprintName in Iter( list ) do

        if ( IndexOf( self.selectedBlueprints, itemBlueprintName ) ~= nil ) then
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
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    for i=1,buildingDescRef.connect.count do

        local connectRecord = buildingDescRef.connect[i]

        for j=1,connectRecord.value.count do

            local connectBlueprintName = connectRecord.value[j]

            local connectMenuIcon = self:GetBuildingMenuIcon( connectBlueprintName )

            if ( connectMenuIcon ~= "" ) then

                return connectMenuIcon
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
        return menuIcon
    end

    local baseBuildingDesc = BuildingService:FindBaseBuilding( blueprintName )
    if ( baseBuildingDesc ~= nil ) then

        local baseBuildingDescRef = reflection_helper( baseBuildingDesc )

        menuIcon = baseBuildingDescRef.menu_icon or ""
        if ( menuIcon ~= "" ) then
            return menuIcon
        end
    end

    return ""
end

return sell_by_type_base
 