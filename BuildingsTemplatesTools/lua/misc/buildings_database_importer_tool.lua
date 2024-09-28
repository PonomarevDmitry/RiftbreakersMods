local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_database_importer_tool' ( buildings_tool_base )

function buildings_database_importer_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_database_importer_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.popupShown = false

    self.allTemplatesName = "all"

    self.selectedTemplate = self.allTemplatesName;

    self.numberFrom = self.data:GetInt("number_from")
    self.numberTo = self.data:GetInt("number_to")
    self.templateFormat = self.data:GetString("template_format")

    local selectedDatabaseNumber = BuildingsTemplatesUtils:GetCurrentPersistentDatabase(self.selector)
    self.selectedDatabaseCaption = "${gui/hud/building_templates/database_" .. string.format( "%02d", selectedDatabaseNumber ) .. "}"

    self.persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(selectedDatabaseNumber)

    self.currentChildTemplate = ""
    self.childEntity = nil

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_importer_tool:UpdateMarker()

    if ( self.currentChildTemplate ~= self.selectedTemplate or self.childEntity == nil) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        local markerBlueprint = "misc/marker_selector_buildings_database_importer_tool_" .. self.selectedTemplate

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        -- Save number of wall layers
        self.currentChildTemplate = self.selectedTemplate
    end
end

function buildings_database_importer_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    if ( self.persistentDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local markerText = self.selectedDatabaseCaption

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        local allIsEmpty = true

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

                allIsEmpty = false

                local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    if ( not self:IsTemplateEqualsToImport(templateString, persistentTemplateString) ) then

                        if ( string.len(templatesStr) > 0 ) then

                            templatesStr = templatesStr .. ", "
                        end

                        templatesStr = templatesStr .. tostring(number)
                    end
                end
            end
        end

        if ( allIsEmpty ) then
            markerText = markerText .. "\n${gui/hud/messages/building_templates/all_templates_empty}"
        else

            if ( string.len(templatesStr) > 0 ) then

                markerText = markerText .. "\n${gui/hud/messages/building_templates/templates_can_be_imported}:\n" .. templatesStr
            else

                markerText = markerText .. "\n${gui/hud/messages/building_templates/all_templates_imported}"
            end
        end

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        markerText = self.selectedDatabaseCaption

        if ( persistentTemplateString == "" ) then

            local templateCaption = "gui/hud/building_templates/persistent_template_" .. self.selectedTemplate

            markerText = markerText .. "\n${" .. templateCaption .. "}:\n${gui/hud/messages/building_templates/empty_template}"
        else

            local persistentBuildingsIcons = self:GetTemplateBuildingsIcons(persistentTemplateString)

            local templateImportCaption = "gui/hud/building_templates/import_persistent_template_" .. self.selectedTemplate

            markerText = markerText .. "\n${" .. templateImportCaption .. "}:\n" .. persistentBuildingsIcons

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)
            if ( templateString ~= "" ) then

                if ( self:IsTemplateEqualsToImport(templateString, persistentTemplateString) ) then

                    markerText = markerText .. "\n${gui/hud/messages/building_templates/equals_except_levels}"
                end

                local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

                local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

                markerText = markerText .. "\n${" .. templateCaption .. "}:\n" .. buildingsIcons
            end
        end
    end

    markerDB:SetString("message_text", markerText)
    markerDB:SetInt("message_visible", 1)
end

function buildings_database_importer_tool:AddedToSelection( entity )
end

function buildings_database_importer_tool:RemovedFromSelection( entity )
end

function buildings_database_importer_tool:OnUpdate()
end

function buildings_database_importer_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_database_importer_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentTemplate = self:CheckTemplateExists(self.selectedTemplate)

    local templatesArray = self:GetTemplatesArray()

    local index = IndexOf( templatesArray, currentTemplate )
    if ( index == nil ) then
        index = 1
    end

    local maxIndex = #templatesArray

    local newIndex = index + change
    if ( newIndex > maxIndex ) then
        newIndex = maxIndex
    elseif( newIndex < 1 ) then
        newIndex = 1
    end

    local newValue = templatesArray[newIndex]

    self.selectedTemplate = newValue

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_importer_tool:CheckTemplateExists( selectedTemplate )

    local templatesArray = self:GetTemplatesArray()

    selectedTemplate = selectedTemplate or templatesArray[1]

    local index = IndexOf(templatesArray, selectedTemplate )

    if ( index == nil ) then

        return templatesArray[1]
    end

    return selectedTemplate
end

function buildings_database_importer_tool:GetTemplatesArray()

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    local result = { self.allTemplatesName }

    if ( ( campaignDatabase ~= nil or selectorDB ~= nil ) and self.persistentDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

                local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    Insert( result, templateSuffix )
                end
            end
        end
    end

    return result
end

function buildings_database_importer_tool:OnActivateSelectorRequest()

    if( self.popupShown ) then

        return
    end

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        if ( not self:DatabaseHasTemplate() ) then
            return
        end

        if ( self:DatabaseHasOverrideTemplate(campaignDatabase, selectorDB) ) then

            self.popupShown = true

            self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates")

            GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/import_all_templates_confirm")

        else

            self:ImportAllTemplatesToToDatabase(campaignDatabase, selectorDB)
        end
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
        if ( persistentTemplateString == "" ) then
            return
        end

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

        if ( templateString == "" ) then

            self:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, self.persistentDatabase)

            self:UpdateMarker()

            self:FillMarkerMessage()
        else

            self.templateNameForImport = templateName
            
            self.popupShown = true

            self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate")

            GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/import_template_confirm")
        end
    end
end

function buildings_database_importer_tool:DatabaseHasTemplate()

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

            return true
        end
    end

    return false
end

function buildings_database_importer_tool:DatabaseHasOverrideTemplate(campaignDatabase, selectorDB)

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)
            if ( templateString ~= "" ) then

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    return true
                end
            end
        end
    end

    return false
end

function buildings_database_importer_tool:OnGuiPopupResultEventAllTemplates( evt )

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates" )

    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    self:ImportAllTemplatesToToDatabase(campaignDatabase, selectorDB)
end

function buildings_database_importer_tool:OnGuiPopupResultEventSingleTemplate( evt )

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate" )

    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    self:ImportTemplateToToDatabase(self.templateNameForImport, campaignDatabase, selectorDB, self.persistentDatabase)

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_importer_tool:ImportAllTemplatesToToDatabase(campaignDatabase, selectorDB)

    if ( self.persistentDatabase == nil ) then
        return
    end

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        self:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, self.persistentDatabase)
    end

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_importer_tool:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, persistentDatabase)

    local persistentTemplateString = persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
    if ( persistentTemplateString == "" ) then
        return
    end

    local templateString = self:GetAvailableBlueprintsInTemplate(persistentTemplateString)

    if ( campaignDatabase ) then
        campaignDatabase:SetString( templateName, templateString )
    end

    if ( selectorDB ) then
        selectorDB:SetString( templateName, templateString )
    end
end

function buildings_database_importer_tool:GetAvailableBlueprintsInTemplate(currentTemplateString)

    local buildingSystemCampaignInfoComponent = EntityService:GetSingletonComponent("BuildingSystemCampaignInfoComponent")
    if ( buildingSystemCampaignInfoComponent == nil ) then
        return
    end

    local buildingSystemCampaignInfoComponentRef = reflection_helper( buildingSystemCampaignInfoComponent )

    local unlocks = buildingSystemCampaignInfoComponentRef.unlocks

    local unlockedHash = {}

    for i=1,unlocks.count do

        local unlocked = unlocks[i]

        unlockedHash[unlocked] = true
    end


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




        local availableBlueprintName = self:GetUnlockedOrMaxAvailableLevel( blueprintName, unlockedHash )
        if ( availableBlueprintName == "" ) then
            goto continue
        end

        if ( hashBlueprints[availableBlueprintName] == nil ) then

            Insert( listBlueprintsNames, availableBlueprintName )

            hashBlueprints[availableBlueprintName] = {}
        end

        local entitiesCoordinatesStringArray = hashBlueprints[availableBlueprintName]

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

function buildings_database_importer_tool:GetUnlockedOrMaxAvailableLevel( blueprintName, unlockedHash )

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

    if ( unlockedHash[buildingDescRef.name] == true ) then
        return blueprintName
    end

    local firstLevelBlueprintName = self:GetFirstLevelBuilding(blueprintName)

    return self:GetMaxAvailableLevel(firstLevelBlueprintName)
end

function buildings_database_importer_tool:IsTemplateEqualsToImport(templateString, persistentTemplateString)

    local newTemplateString = self:GetAvailableBlueprintsInTemplate(persistentTemplateString)

    return BuildingsTemplatesUtils:IsTemplateEquals(templateString, newTemplateString)
end

function buildings_database_importer_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_importer_tool