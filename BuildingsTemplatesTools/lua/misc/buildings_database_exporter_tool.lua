local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_database_exporter_tool' ( buildings_tool_base )

function buildings_database_exporter_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_database_exporter_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.popupShown = false
    self.timeoutTime = nil

    self.allTemplatesName = "all"

    self.selectedTemplate = self.allTemplatesName;

    self.numberFrom = 1
    self.numberTo = BuildingsTemplatesUtils:GetMaxAvailableTemplate()
    self.templateFormat = self.data:GetString("template_format")

    local selectedDatabaseNumber = BuildingsTemplatesUtils:GetCurrentPersistentDatabase(self.selector)
    self.selectedDatabaseCaption = "${gui/hud/building_templates/database_" .. string.format( "%02d", selectedDatabaseNumber ) .. "}"

    self.persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(selectedDatabaseNumber)

    self.currentChildTemplate = ""

    local markerBlueprint = "misc/marker_selector_buildings_database_exporter_tool"
    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    self.templateEntities = {}

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_exporter_tool:UpdateMarker()

    if ( self.currentChildTemplate == self.selectedTemplate) then
        return
    end

    local markerBlueprint = ""

    if ( self.selectedTemplate == self.allTemplatesName ) then

        if ( self.firstNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.firstNumberEntity)
            self.firstNumberEntity = nil
        end

        if ( self.secondNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.secondNumberEntity)
            self.secondNumberEntity = nil
        end

        if ( self.allNumberEntity == nil) then

            markerBlueprint = "misc/marker_buildings_templates_numbers_all"

            self.allNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
        end

    else

        if ( self.allNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.allNumberEntity)
            self.allNumberEntity = nil
        end

        local number = tonumber(self.selectedTemplate)

        local firstNumber = math.floor( number / 10 )
        local secondNumber = number % 10

        if ( firstNumber ~= 0 ) then
            markerBlueprint = "misc/marker_buildings_templates_numbers_" .. tostring(firstNumber) .. "x"

            if ( self.firstNumberEntity == nil or EntityService:GetBlueprintName(self.firstNumberEntity) ~= markerBlueprint ) then

                if ( self.firstNumberEntity ~= nil) then
                    EntityService:RemoveEntity(self.firstNumberEntity)
                    self.firstNumberEntity = nil
                end  

                self.firstNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
            end
        else

            if ( self.firstNumberEntity ~= nil) then
                EntityService:RemoveEntity(self.firstNumberEntity)
                self.firstNumberEntity = nil
            end            
        end

        markerBlueprint = "misc/marker_buildings_templates_numbers_x" .. tostring(secondNumber)

        if ( self.secondNumberEntity == nil or EntityService:GetBlueprintName(self.secondNumberEntity) ~= markerBlueprint ) then

            if ( self.secondNumberEntity ~= nil) then
                EntityService:RemoveEntity(self.secondNumberEntity)
                self.secondNumberEntity = nil
            end  

            self.secondNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
        end
    end

    self.currentChildTemplate = self.selectedTemplate
end

function buildings_database_exporter_tool:FillMarkerMessage()

    self:CleanInformationTemplateEntities()

    self.selectedTemplate = self:CheckTemplateExists(self.selectedTemplate)

    self:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    if ( self.persistentDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        local allIsEmpty = true

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( templateString ~= nil and templateString ~= "" ) then

                allIsEmpty = false

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    if ( string.len(templatesStr) > 0 ) then

                        templatesStr = templatesStr .. ", "
                    end

                    templatesStr = templatesStr .. tostring(number)
                end
            end
        end

        local markerText = ""

        if ( allIsEmpty ) then
            markerText = "${gui/hud/messages/building_templates/all_templates_empty}"
        else

            if ( string.len(templatesStr) > 0 ) then

                markerText = "${gui/hud/messages/building_templates/templates_can_be_exported}:\n" .. templatesStr
            else

                markerText = "${gui/hud/messages/building_templates/all_templates_exported}"
            end
        end

        markerText = markerText .. "\n" .. self.selectedDatabaseCaption

        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("menu_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

        local markerText = ""

        if ( templateString == "" ) then

            local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

            markerText = "${" .. templateCaption .. "}:\n${gui/hud/messages/building_templates/empty_template}"

            markerText = markerText .. "\n" .. self.selectedDatabaseCaption
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

            local templateExportCaption = "gui/hud/building_templates/export_template_" .. self.selectedTemplate

            markerText = "${" .. templateExportCaption .. "}:\n" .. buildingsIcons

            markerText = markerText .. "\n" .. self.selectedDatabaseCaption

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
            if ( persistentTemplateString ~= "" ) then

                if ( self:IsTemplateEqualsToImport(templateString, persistentTemplateString) ) then

                    markerText = markerText .. "\n${gui/hud/messages/building_templates/equals_except_levels}"
                end

                local persistentBuildingsIcons = self:GetTemplateBuildingsIcons(persistentTemplateString)

                local templateCaption = "gui/hud/building_templates/persistent_template_" .. self.selectedTemplate

                markerText = markerText .. "\n${" .. templateCaption .. "}:\n" .. persistentBuildingsIcons
            end

            self:SpawnInformationBuildinsTemplates(templateString)
        end
        
        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("menu_visible", 1)
    end
end

function buildings_database_exporter_tool:AddedToSelection( entity )
end

function buildings_database_exporter_tool:RemovedFromSelection( entity )
end

function buildings_database_exporter_tool:OnUpdate()
end

function buildings_database_exporter_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_database_exporter_tool:OnRotateSelectorRequest(evt)

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

function buildings_database_exporter_tool:CheckTemplateExists( selectedTemplate )

    local templatesArray = self:GetTemplatesArray()

    if ( selectedTemplate == nil ) then

        return templatesArray[1]
    end

    local index = IndexOf( templatesArray, selectedTemplate )
    if ( index ~= nil ) then
        
        return selectedTemplate
    end

    local selectedTemplateNumber = tonumber( selectedTemplate )

    if ( selectedTemplateNumber ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local newNumber = selectedTemplateNumber - number

            if ( self.numberFrom <= newNumber and newNumber <= self.numberTo ) then

                local templateSuffix = string.format( "%02d", newNumber )

                local index = IndexOf( templatesArray, templateSuffix )

                if ( index ~= nil ) then
        
                    return templatesArray[index]
                end
            end

            local newNumber = selectedTemplateNumber + number

            if ( self.numberFrom <= newNumber and newNumber <= self.numberTo ) then

                local templateSuffix = string.format( "%02d", newNumber )

                local index = IndexOf( templatesArray, templateSuffix )

                if ( index ~= nil ) then
        
                    return templatesArray[index]
                end
            end
        end
    end

    return templatesArray[1]
end

function buildings_database_exporter_tool:GetTemplatesArray()

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    local result = { self.allTemplatesName }

    if ( ( globalPlayerEntity ~= nil or selectorDB ~= nil ) and self.persistentDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

            if ( templateString ~= nil and templateString ~= "" ) then

                local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    Insert( result, templateSuffix )
                end
            end
        end
    end

    return result
end

function buildings_database_exporter_tool:OnActivateSelectorRequest()

    if( self.popupShown ) then

        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        if ( not self:DatabaseHasTemplate(globalPlayerEntity, selectorDB) ) then
            return
        end

        if ( self:DatabaseHasOverrideTemplate(globalPlayerEntity, selectorDB) ) then

            self.popupShown = true

            self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates")

            GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/export_all_templates_confirm")

        else

            self:SaveTimeout()

            self:ExportAllTemplatesToToDatabase(globalPlayerEntity, selectorDB)
        end
    else

        local templateName = self.templateFormat .. self.selectedTemplate
        
        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)
        if ( templateString == "" ) then
            return
        end

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString == "" ) then

            self:SaveTimeout()

            self:ExportTemplateToToDatabase(templateName, globalPlayerEntity, selectorDB, self.persistentDatabase)

            self:UpdateMarker()

            self:FillMarkerMessage()
        else

            self.templateNameForExport = templateName
            
            self.popupShown = true

            self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate")

            GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/export_template_confirm")
        end
    end
end

function buildings_database_exporter_tool:DatabaseHasTemplate(globalPlayerEntity, selectorDB)

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

        if ( templateString ~= nil and templateString ~= "" ) then

            return true
        end
    end

    return false
end

function buildings_database_exporter_tool:DatabaseHasOverrideTemplate(globalPlayerEntity, selectorDB)

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)

        if ( templateString ~= nil and templateString ~= "" ) then
        
            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
            
            if ( persistentTemplateString ~= "" ) then

                if ( not BuildingsTemplatesUtils:IsTemplateEquals(templateString, persistentTemplateString) ) then

                    return true
                end
            end
        end
    end

    return false
end

function buildings_database_exporter_tool:SaveTimeout()

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown
end

function buildings_database_exporter_tool:OnGuiPopupResultEventAllTemplates( evt )

    self:SaveTimeout()

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates" )

    if ( evt:GetResult() ~= "button_yes" ) then
        self.popupShown = false
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    self:ExportAllTemplatesToToDatabase(globalPlayerEntity, selectorDB)

    self.popupShown = false
end

function buildings_database_exporter_tool:ExportAllTemplatesToToDatabase(globalPlayerEntity, selectorDB)

    if ( self.persistentDatabase == nil ) then
        return
    end

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        self:ExportTemplateToToDatabase(templateName, globalPlayerEntity, selectorDB, self.persistentDatabase)
    end

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_exporter_tool:OnGuiPopupResultEventSingleTemplate( evt )

    self:SaveTimeout()

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate" )

    if ( evt:GetResult() ~= "button_yes" ) then
        self.popupShown = false
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    self:ExportTemplateToToDatabase(self.templateNameForExport, globalPlayerEntity, selectorDB, self.persistentDatabase)

    self:UpdateMarker()

    self:FillMarkerMessage()

    self.popupShown = false
end

function buildings_database_exporter_tool:ExportTemplateToToDatabase(templateName, globalPlayerEntity, selectorDB, persistentDatabase)

    local currentTemplateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB)
    if ( currentTemplateString == "" ) then
        return
    end

    if ( persistentDatabase ) then
        persistentDatabase:SetString( templateName, currentTemplateString )
    end
end

function buildings_database_exporter_tool:IsTemplateEqualsToImport(templateString, persistentTemplateString)

    local newTemplateString = self:GetAvailableBlueprintsInTemplate(persistentTemplateString)

    return BuildingsTemplatesUtils:IsTemplateEquals(templateString, newTemplateString)
end

function buildings_database_exporter_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( self.firstNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.firstNumberEntity)
        self.firstNumberEntity = nil
    end

    if ( self.secondNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.secondNumberEntity)
        self.secondNumberEntity = nil
    end

    if ( self.allNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.allNumberEntity)
        self.allNumberEntity = nil
    end

    self:CleanInformationTemplateEntities()

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_exporter_tool