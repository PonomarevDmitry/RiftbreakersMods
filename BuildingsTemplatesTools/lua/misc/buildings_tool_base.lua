local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")
local TemplatesSerializeUtils = require("lua/misc/buildings_serialize_utils.lua")

class 'buildings_tool_base' ( tool )

function buildings_tool_base:__init()
    tool.__init(self,self)
end

function buildings_tool_base:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function buildings_tool_base:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function buildings_tool_base:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function buildings_tool_base:HideMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    markerDB:SetString("message_text", "")
    markerDB:SetInt("message_visible", 0)
end

function buildings_tool_base:GetTemplateBuildingsIcons(templateString)

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

    local listIconsNames = {}
    local hashIconsCount = {}

    for template in Iter( blueprintsGroupsArray ) do

        -- Split by ":" blueprint template
        local blueprintValuesArray = Split( template, delimiterBlueprintName )

        -- Only 2 values in blueprintValuesArray
        if ( #blueprintValuesArray ~= 2 ) then
            goto continue
        end

        -- First blueprintName
        local blueprintName = blueprintValuesArray[1]
        -- Second array with entities coordinates
        local entitiesCoordinatesString = blueprintValuesArray[2]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
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

        local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )

        if ( menuIcon == "" ) then
            goto continue
        end

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )
        if ( #entitiesCoordinatesArray > 0) then

            if ( hashIconsCount[menuIcon] == nil ) then

                Insert( listIconsNames, menuIcon )

                hashIconsCount[menuIcon] = 0
            end

            hashIconsCount[menuIcon] = hashIconsCount[menuIcon] + #entitiesCoordinatesArray
        end

        ::continue::
    end

    local markerText = ""

    local lineLength = 0
    local maxLineLength = 40

    for menuIcon in Iter( listIconsNames ) do

        local count = hashIconsCount[menuIcon]

        if ( count > 0 ) then

            if ( lineLength > 0 ) then

                lineLength = lineLength + 1
                markerText = markerText .. ","
            end

            local countString = tostring(count)
            local countStringLen = string.len(countString) + 2

            if ( lineLength + countStringLen + 1 > maxLineLength ) then

                markerText = markerText .. "\n"
                lineLength = 0

            else
                markerText = markerText .. " "
                lineLength = lineLength + 1
            end

            markerText = markerText .. '<img="' .. menuIcon .. '">x' .. countString
            lineLength = lineLength + countStringLen
        end
    end

    return markerText
end

function buildings_tool_base:GetTemplateBuildingsIconsToUpgrade(templateString)

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

    local listIconsNames = {}
    local hashIconsCount = {}

    local listIconsNamesToUpgrade = {}
    local hashIconsCountToUpgrade = {}

    for template in Iter( blueprintsGroupsArray ) do

        -- Split by ":" blueprint template
        local blueprintValuesArray = Split( template, delimiterBlueprintName )

        -- Only 2 values in blueprintValuesArray
        if ( #blueprintValuesArray ~= 2 ) then
            goto continue
        end

        -- First blueprintName
        local blueprintName = blueprintValuesArray[1]
        -- Second array with entities coordinates
        local entitiesCoordinatesString = blueprintValuesArray[2]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
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

        local menuIcon = self:GetBuildingMenuIcon( blueprintName, buildingDescRef )

        if ( menuIcon == "" ) then
            goto continue
        end


        local maxUpgradeBlueprintName = self:GetMaxAvailableLevel( blueprintName )
        if ( maxUpgradeBlueprint == "" ) then
            goto continue
        end

        local list = listIconsNames
        local hash = hashIconsCount

        if ( maxUpgradeBlueprintName ~= blueprintName ) then

            list = listIconsNamesToUpgrade
            hash = hashIconsCountToUpgrade
        end

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )
        if ( #entitiesCoordinatesArray > 0) then

            if ( hash[menuIcon] == nil ) then

                Insert( list, menuIcon )

                hash[menuIcon] = 0
            end

            hash[menuIcon] = hash[menuIcon] + #entitiesCoordinatesArray
        end

        ::continue::
    end

    local maxLineLength = 40

    local markerText = ""
    local lineLength = 0

    for menuIcon in Iter( listIconsNames ) do

        local count = hashIconsCount[menuIcon]

        if ( count > 0 ) then

            if ( lineLength > 0 ) then

                lineLength = lineLength + 1
                markerText = markerText .. ","
            end

            local countString = tostring(count)
            local countStringLen = string.len(countString) + 2

            if ( lineLength + countStringLen + 1 > maxLineLength ) then

                markerText = markerText .. "\n"
                lineLength = 0

            else
                markerText = markerText .. " "
                lineLength = lineLength + 1
            end

            markerText = markerText .. '<img="' .. menuIcon .. '">x' .. countString
            lineLength = lineLength + countStringLen
        end
    end

    local markerTextToUpgrade = ""
    local lineLength = 0

    for menuIcon in Iter( listIconsNamesToUpgrade ) do

        local count = hashIconsCountToUpgrade[menuIcon]

        if ( count > 0 ) then

            if ( lineLength > 0 ) then

                lineLength = lineLength + 1
                markerTextToUpgrade = markerTextToUpgrade .. ","
            end

            local countString = tostring(count)
            local countStringLen = string.len(countString) + 2

            if ( lineLength + countStringLen + 1 > maxLineLength ) then

                markerTextToUpgrade = markerTextToUpgrade .. "\n"
                lineLength = 0

            else
                markerTextToUpgrade = markerTextToUpgrade .. " "
                lineLength = lineLength + 1
            end

            markerTextToUpgrade = markerTextToUpgrade .. '<img="' .. menuIcon .. '">x' .. countString
            lineLength = lineLength + countStringLen
        end
    end

    return markerText, markerTextToUpgrade
end

function buildings_tool_base:CanUpgradeTemplate(templateString)

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

    for template in Iter( blueprintsGroupsArray ) do

        -- Split by ":" blueprint template
        local blueprintValuesArray = Split( template, delimiterBlueprintName )

        -- Only 2 values in blueprintValuesArray
        if ( #blueprintValuesArray ~= 2 ) then
            goto continue
        end

        -- First blueprintName
        local blueprintName = blueprintValuesArray[1]
        -- Second array with entities coordinates
        local entitiesCoordinatesString = blueprintValuesArray[2]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
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


        local maxUpgradeBlueprintName = self:GetMaxAvailableLevel( blueprintName )
        if ( maxUpgradeBlueprintName == "" ) then
            goto continue
        end

        if ( maxUpgradeBlueprintName ~= blueprintName ) then

            return true
        end

        ::continue::
    end

    return false
end

function buildings_tool_base:GetBuildingMenuIcon( blueprintName, buildingDescRef )

    self.cacheBlueprintsMenuIcons = self.cacheBlueprintsMenuIcons or {}

    if ( self.cacheBlueprintsMenuIcons[blueprintName] == nil ) then

        self.cacheBlueprintsMenuIcons[blueprintName] = self:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )
    end

    return self.cacheBlueprintsMenuIcons[blueprintName]
end

function buildings_tool_base:CalculateBuildingMenuIcon( blueprintName, buildingDescRef )

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

function buildings_tool_base:UpgradeBlueprintsInTemplate(currentTemplateString)

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    -- templateString format:
    -- blueprint1:ent1PosX,ent1PosZ,ent1OrientY,ent1OrientW;ent2PosX,ent2PosZ,ent2OrientY,ent2OrientW|blueprint2:ent3PosX,ent3PosZ,ent3OrientY,ent3OrientW;ent4PosX,ent4PosZ,ent4OrientY,ent4OrientW

    -- Delimiter between blueprints groups: "|"
    -- Delimiter between blueprint name and array of entities coordinates: ":"
    -- Delimiter between entities in array of entities coordinates: ";"
    -- Delimiter between coordinates for single entity: ","
    -- blueprint1, blueprint2 - blueprints names

    -- ent1PosX, ent2PosX, ent3PosX, ent4PosX - entities relative position.x
    -- ent1PosZ, ent2PosZ, ent3PosZ, ent4PosZ - entities relative position.z

    -- ent1OrientY, ent2OrientY, ent3OrientY, ent4OrientY - entities orientation.y
    -- ent1OrientW, ent2OrientW, ent3OrientW, ent4OrientW - entities orientation.w



    local blueprintsGroupsArray = Split( currentTemplateString, delimiterBlueprintsGroups )


    local hashBlueprints = {}
    local listBlueprintsNames = {}

    for template in Iter( blueprintsGroupsArray ) do

        -- Split by ":" blueprint template
        local blueprintValuesArray = Split( template, delimiterBlueprintName )

        -- Only 2 values in blueprintValuesArray
        if ( #blueprintValuesArray ~= 2 ) then
            goto continue
        end

        -- First blueprintName
        local blueprintName = blueprintValuesArray[1]
        -- Second array with entities coordinates
        local entitiesCoordinatesString = blueprintValuesArray[2]

        if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
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




        local maxUpgradeBlueprintName = self:GetMaxAvailableLevel( blueprintName )
        if ( maxUpgradeBlueprintName == "" ) then
            goto continue
        end

        if ( hashBlueprints[maxUpgradeBlueprintName] == nil ) then

            Insert( listBlueprintsNames, maxUpgradeBlueprintName )

            hashBlueprints[maxUpgradeBlueprintName] = {}
        end

        local entitiesCoordinatesStringArray = hashBlueprints[maxUpgradeBlueprintName]

        if ( #entitiesCoordinatesStringArray > 0 ) then
            Insert( entitiesCoordinatesStringArray, delimiterEntitiesArray )
        end

        Insert( entitiesCoordinatesStringArray, entitiesCoordinatesString )

        ::continue::
    end



    local templateStringArray = {}

    for entityBlueprint in Iter( listBlueprintsNames ) do

        if ( #templateStringArray > 0 ) then
            Insert( templateStringArray, delimiterBlueprintsGroups )
        end

        Insert( templateStringArray, entityBlueprint )
        Insert( templateStringArray, delimiterBlueprintName )

        local entitiesCoordinates = hashBlueprints[entityBlueprint]

        for str in Iter( entitiesCoordinates ) do
            Insert( templateStringArray, str )
        end
    end

    local templateString = table.concat( templateStringArray )

    return templateString
end

function buildings_tool_base:GetMaxAvailableLevel( blueprintName )

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

    if ( buildingDescRef.upgrade ~= nil and buildingDescRef.upgrade ~= "" ) then

        if ( self:IsBlueprintAvailable( buildingDescRef.upgrade ) ) then

            return self:GetMaxAvailableLevel( buildingDescRef.upgrade )
        end
    end

    return blueprintName
end

function buildings_tool_base:IsBlueprintAvailable( blueprintName )

    if ( BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        return true
    end

    local researchName = self:GetResearchForUpgrade( blueprintName ) or ""
    if ( researchName ~= "" ) then

        if ( PlayerService:IsResearchUnlocked( researchName ) ) then
            return true
        end
    end

    return false
end

function buildings_tool_base:GetResearchForUpgrade( blueprintName )

    self.cacheBlueprintsResearches = self.cacheBlueprintsResearches or {}

    if ( self.cacheBlueprintsResearches[blueprintName] == nil ) then

        self.cacheBlueprintsResearches[blueprintName] = self:CalculateResearchForUpgrade( blueprintName )
    end

    return self.cacheBlueprintsResearches[blueprintName]
end

function buildings_tool_base:CalculateResearchForUpgrade( blueprintName )

    local researchComponent = reflection_helper( EntityService:GetSingletonComponent("ResearchSystemDataComponent") )

    local categories = researchComponent.research

    for i=1,categories.count do

        local category = categories[i]
        local category_nodes = category.nodes

        for j=1,category_nodes.count do

            local node = category_nodes[j]

            local awards = node.research_awards
            for k=1,awards.count do

                if awards[k].blueprint == blueprintName then

                    return node.research_name
                end
            end
        end
    end

    return ""
end

return buildings_tool_base