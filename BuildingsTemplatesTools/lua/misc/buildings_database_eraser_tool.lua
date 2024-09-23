local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_database_eraser_tool' ( buildings_tool_base )

function buildings_database_eraser_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_database_eraser_tool:OnInit()

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

    self.persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(self.selectedDatabaseNumber)

    self.currentChildTemplate = ""
    self.childEntity = nil

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_eraser_tool:UpdateMarker()

    if ( self.currentChildTemplate ~= self.selectedTemplate or self.childEntity == nil) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        local markerBlueprint = "misc/marker_selector_buildings_database_eraser_tool_" .. self.selectedTemplate

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        -- Save number of wall layers
        self.currentChildTemplate = self.selectedTemplate
    end
end

function buildings_database_eraser_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    if ( self.persistentDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    self.selectedTemplate = self:CheckTemplateExists(self.selectedTemplate)

    self:UpdateMarker()

    local markerText = self.selectedDatabaseCaption .. "\n"

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

                if ( string.len(templatesStr) > 0 ) then

                    templatesStr = templatesStr .. ", "
                end

                templatesStr = templatesStr .. tostring(number)
            end
        end

        if ( string.len(templatesStr) > 0 ) then

            markerText = markerText .. "${gui/hud/messages/building_templates/templates_can_be_erased}:\n" .. templatesStr
        else

            markerText = markerText .. "${gui/hud/messages/building_templates/all_templates_empty}"
        end

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("message_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateEraseCaption = "gui/hud/building_templates/erase_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString == "" ) then

            markerText = markerText .. "${" .. templateCaption .. "}:\n${gui/hud/messages/buildings_picker_tool/empty_template}"
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(persistentTemplateString)

            markerText = markerText .. "${" .. templateEraseCaption .. "}:\n" .. buildingsIcons
        end

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("message_visible", 1)
    end
end

function buildings_database_eraser_tool:AddedToSelection( entity )
end

function buildings_database_eraser_tool:RemovedFromSelection( entity )
end

function buildings_database_eraser_tool:OnUpdate()
end

function buildings_database_eraser_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_database_eraser_tool:OnRotateSelectorRequest(evt)

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

function buildings_database_eraser_tool:CheckTemplateExists( selectedTemplate )

    local templatesArray = self:GetTemplatesArray()

    selectedTemplate = selectedTemplate or templatesArray[1]

    local index = IndexOf( templatesArray, selectedTemplate )

    if ( index == nil ) then

        return templatesArray[1]
    end

    return selectedTemplate
end

function buildings_database_eraser_tool:GetTemplatesArray()

    local result = { self.allTemplatesName }

    if ( self.persistentDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

            if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

                Insert( result, templateSuffix )
            end
        end
    end

    return result
end

function buildings_database_eraser_tool:OnActivateSelectorRequest()

    if( self.popupShown ) then

        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        if ( not self:DatabaseHasTemplate() ) then
            return
        end

        self.popupShown = true

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates")

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/buildings_picker_tool/clear_all_templates_confirm")
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
        if ( persistentTemplateString == "" ) then
            return
        end

        self.templateNameForErase = self.selectedTemplate

        self.popupShown = true

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate")

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/buildings_picker_tool/clear_template_confirm")
    end
end

function buildings_database_eraser_tool:DatabaseHasTemplate()

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString ~= nil and persistentTemplateString ~= "" ) then

            return true
        end
    end

    return false
end

function buildings_database_eraser_tool:OnGuiPopupResultEventSingleTemplate( evt )

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate" )

    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    local templateName = self.templateFormat .. tostring(self.templateNameForErase)

    self.persistentDatabase:SetString( templateName, "" )

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_eraser_tool:OnGuiPopupResultEventAllTemplates( evt )

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates" )

    self.popupShown = false

    if ( evt:GetResult() ~= "button_yes" ) then
        return
    end

    if ( self.persistentDatabase == nil ) then
        return
    end

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        self.persistentDatabase:SetString( templateName, "" )
    end

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_eraser_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_eraser_tool