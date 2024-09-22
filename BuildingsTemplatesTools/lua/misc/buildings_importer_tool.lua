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

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedDatabaseNumber = selectorDB:GetIntOrDefault("$buildings_database_select_config", 1)
    self.selectedDatabaseCaption = "${gui/hud/building_templates/database_" .. string.format( "%02d", self.selectedDatabaseNumber ) .. "}"

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
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(self.selectedDatabaseNumber)
    if ( persistentDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        local allIsEmpty = true

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

            local persistentTemplateString = persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

                allIsEmpty = false

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    if ( string.len(templatesStr) > 0 ) then

                        templatesStr = templatesStr .. ", "
                    end

                    templatesStr = templatesStr .. tostring(number)
                end
            end
        end

        if ( allIsEmpty ) then
            markerDB:SetString("message_text", "gui/hud/messages/building_templates/all_templates_empty")
        else

            local markerText = self.selectedDatabaseCaption

            if ( string.len(templatesStr) > 0 ) then

                markerText = markerText .. "\n${gui/hud/building_templates/templates_can_be_imported}:\n" .. templatesStr
            else

                markerText = markerText .. "\n${gui/hud/messages/building_templates/all_templates_imported}"
            end

                markerDB:SetString("message_text", markerText)
        end

        markerDB:SetInt("message_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateImportCaption = "gui/hud/building_templates/import_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

        local persistentTemplateString = persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString == "" ) then

            local markerText = "${gui/hud/building_templates/persistent} ${" .. templateCaption .. "}:\n${gui/hud/messages/buildings_picker_tool/empty_template}"

            markerDB:SetString("message_text", markerText)
        else

            local persistentBuildingsIcons = self:GetTemplateBuildingsIcons(persistentTemplateString)

            local markerText = self.selectedDatabaseCaption

            markerText = markerText .. "\n${" .. templateImportCaption .. "}:\n" .. persistentBuildingsIcons

            if ( templateString ~= "" ) then

                local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

                markerText = markerText .. "\n${" .. templateCaption .. "}:\n" .. buildingsIcons
            end

            markerDB:SetString("message_text", markerText)
        end

        markerDB:SetInt("message_visible", 1)
    end
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

    --local selectorDB = EntityService:GetDatabase( self.selector )
    --selectorDB:SetInt(self.configNameCellGaps, newValue)

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

    local persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(self.selectedDatabaseNumber)

    local result = { self.allTemplatesName }

    if ( ( campaignDatabase ~= nil or selectorDB ~= nil ) and persistentDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local persistentTemplateString = persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

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

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
        return
    end

    local persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(self.selectedDatabaseNumber)
    if ( persistentDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            self:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, persistentDatabase)
        end
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        self:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, persistentDatabase)
    end

    self:FillMarkerMessage()
end

function buildings_database_importer_tool:ImportTemplateToToDatabase(templateName, campaignDatabase, selectorDB, persistentDatabase)

    local currentTemplateString = persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
    if ( currentTemplateString == "" ) then
        return
    end

    local templateString = currentTemplateString

    if ( campaignDatabase ) then
        campaignDatabase:SetString( templateName, templateString )
    end

    if ( selectorDB ) then
        selectorDB:SetString( templateName, templateString )
    end
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