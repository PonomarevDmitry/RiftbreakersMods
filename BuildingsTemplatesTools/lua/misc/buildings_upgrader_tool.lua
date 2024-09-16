local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_upgrader_tool' ( buildings_tool_base )

function buildings_upgrader_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_upgrader_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.popupShown = false

    self.allTemplatesName = "all"

    self.selectedTemplate = self.allTemplatesName;

    self.numberFrom = self.data:GetInt("number_from")
    self.numberTo = self.data:GetInt("number_to")
    self.templateFormat = self.data:GetString("template_format")

    self.currentChildTemplate = ""
    self.childEntity = nil

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:UpdateMarker()

    if ( self.currentChildTemplate ~= self.selectedTemplate or self.childEntity == nil) then

        -- Destroy old marker
        if (self.childEntity ~= nil) then

            EntityService:RemoveEntity(self.childEntity)
            self.childEntity = nil
        end

        local markerBlueprint = "misc/marker_selector_buildings_upgrader_tool_" .. self.selectedTemplate

        -- Create new marker
        self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        -- Save number of wall layers
        self.currentChildTemplate = self.selectedTemplate
    end
end

function buildings_upgrader_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
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

            if ( templateString ~= nil and templateString ~= "" ) then

                allIsEmpty = false

                if ( self:CanUpgradeTemplate(templateString) ) then

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

            if ( string.len(templatesStr) > 0 ) then

                local markerText = "${gui/hud/building_templates/templates_can_be_upgraded}:\n" .. templatesStr

                markerDB:SetString("message_text", markerText)
            else

                markerDB:SetString("message_text", "gui/hud/messages/building_templates/all_templates_upgraded")
            end
        end

        markerDB:SetInt("message_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateUpgradeCaption = "gui/hud/building_templates/upgrade_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

        if ( templateString == "" ) then

            local markerText = "${" .. templateCaption .. "}: ${gui/hud/messages/buildings_picker_tool/empty_template}"

            markerDB:SetString("message_text", markerText)
        else

            local upgradedList, toUpgradeList = self:GetTemplateBuildingsIconsToUpgrade(templateString)

            if ( string.len(upgradedList) == 0 and string.len(toUpgradeList) == 0 ) then

                markerDB:SetString("message_text", "gui/hud/messages/buildings_tool_base/template_already_created")

            else

                local markerText = ""

                if ( string.len(upgradedList) > 0 ) then
                    markerText = "${" .. templateCaption .. "}:\n" .. upgradedList

                    if ( string.len(toUpgradeList) > 0 ) then
                        markerText = markerText .. "\n${gui/hud/building_templates/can_be_upgraded}:\n" .. toUpgradeList
                    end
                else
                    markerText = "${" .. templateUpgradeCaption .. "}:\n" .. toUpgradeList
                end

                markerDB:SetString("message_text", markerText)
            end
        end

        markerDB:SetInt("message_visible", 1)
    end
end

function buildings_upgrader_tool:AddedToSelection( entity )
end

function buildings_upgrader_tool:RemovedFromSelection( entity )
end

function buildings_upgrader_tool:OnUpdate()
end

function buildings_upgrader_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_upgrader_tool:OnRotateSelectorRequest(evt)

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
        newIndex = 1
    elseif( newIndex == 0 ) then
        newIndex = maxIndex
    end

    local newValue = templatesArray[newIndex]

    self.selectedTemplate = newValue

    --local selectorDB = EntityService:GetDatabase( self.selector )
    --selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:CheckTemplateExists( selectedTemplate )

    local templatesArray = self:GetTemplatesArray()

    selectedTemplate = selectedTemplate or templatesArray[1]

    local index = IndexOf(templatesArray, selectedTemplate )

    if ( index == nil ) then

        return templatesArray[1]
    end

    return selectedTemplate
end

function buildings_upgrader_tool:GetTemplatesArray()

    if ( self.templatesArray == nil ) then

        self.templatesArray = { self.allTemplatesName }

        for number=self.numberFrom,self.numberTo do

            local templateName = string.format( "%02d", number )

            Insert( self.templatesArray, templateName )
        end
    end

    return self.templatesArray
end

function buildings_upgrader_tool:OnActivateSelectorRequest()

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            self:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, campaignDatabase, selectorDB)
        end
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        self:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, campaignDatabase, selectorDB)
    end

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, campaignDatabase, selectorDB)

    local currentTemplateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)
    if ( currentTemplateString == "" ) then
        return
    end

    local templateString = self:UpgradeBlueprintsInTemplate(currentTemplateString)

    if ( campaignDatabase ) then
        campaignDatabase:SetString( templateName, templateString )
    end

    if ( selectorDB ) then
        selectorDB:SetString( templateName, templateString )
    end
end

function buildings_upgrader_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_upgrader_tool