local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_swap_templates_tool' ( buildings_tool_base )

function buildings_swap_templates_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_swap_templates_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.popupShown = false

    self.childEntity = EntityService:SpawnAndAttachEntity( "misc/marker_selector_buildings_swap_templates_tool", self.selector )

    self.selectedTemplateFrom = "01";
    self.selectedTemplateTo = "01";

    self.numberFrom = 1
    self.numberTo = BuildingsTemplatesUtils:GetMaxAvailableTemplate()
    self.templateFormat = self.data:GetString("template_format")

    self.playerEntity = PlayerService:GetPlayerControlledEnt( self.playerId )

    self:FillMarkerMessage()
end

function buildings_swap_templates_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( campaignDatabase == nil and selectorDB == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local templatesArray = self:GetTemplatesArray()

    self.selectedTemplateFrom = self:CheckTemplateExists(self.selectedTemplateFrom, templatesArray)

    self.selectedTemplateTo = self:CheckTemplateExists(self.selectedTemplateTo, templatesArray)

    local markerText = ""

    do

        local templateName = self.templateFormat .. self.selectedTemplateFrom

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplateFrom

        markerText = markerText .. "${" .. templateCaption .. "}:"

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

        if ( templateString == "" ) then

            markerText = markerText .. "\n${gui/hud/messages/building_templates/empty_template}"
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

            markerText = markerText .. "\n" .. buildingsIcons
        end
    end

    do
        local templateName = self.templateFormat .. self.selectedTemplateTo

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplateTo

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, campaignDatabase, selectorDB)

        markerText = markerText .. "\n${" .. templateCaption .. "}:"

        if ( templateString == "" ) then

            markerText = markerText .. "\n${gui/hud/messages/building_templates/empty_template}"
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

            markerText = markerText .. "\n" .. buildingsIcons
        end
    end

    markerDB:SetString("message_text", markerText)

    markerDB:SetInt("message_visible", 1)
end

function buildings_swap_templates_tool:AddedToSelection( entity )
end

function buildings_swap_templates_tool:RemovedFromSelection( entity )
end

function buildings_swap_templates_tool:OnUpdate()
end

function buildings_swap_templates_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_swap_templates_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local playerPosition = EntityService:GetPosition(self.playerEntity)
    
    local entityPosition = EntityService:GetPosition(self.entity)

    local isFromTemplate = ( entityPosition.x >= playerPosition.x )

    local templatesArray = self:GetTemplatesArray()

    local currentTemplate = nil

    if ( isFromTemplate ) then

        currentTemplate = self.selectedTemplateFrom
    else
        
        currentTemplate = self.selectedTemplateTo
    end

    currentTemplate = self:CheckTemplateExists(currentTemplate, templatesArray)

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

    if ( isFromTemplate ) then

        self.selectedTemplateFrom = newValue
    else
        
        self.selectedTemplateTo = newValue
    end

    self:FillMarkerMessage()
end

function buildings_swap_templates_tool:CheckTemplateExists( selectedTemplate, templatesArray )

    selectedTemplate = selectedTemplate or templatesArray[1]

    local index = IndexOf( templatesArray, selectedTemplate )

    if ( index == nil ) then

        return templatesArray[1]
    end

    return selectedTemplate
end

function buildings_swap_templates_tool:GetTemplatesArray()

    if ( self.templatesArray == nil ) then

        local result = { }

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            Insert( result, templateSuffix )
        end

        self.templatesArray = result
    end

    return self.templatesArray
end

function buildings_swap_templates_tool:OnActivateSelectorRequest()

    local campaignDatabase, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)
    if ( campaignDatabase == nil and selectorDB == nil ) then
        return
    end

    if ( self.selectedTemplateFrom == self.selectedTemplateTo ) then
        return
    end

    local templateNameFrom = self.templateFormat .. self.selectedTemplateFrom
    local templateStringFrom = BuildingsTemplatesUtils:GetTemplateString(templateNameFrom, campaignDatabase, selectorDB)

    local templateNameTo = self.templateFormat .. self.selectedTemplateTo
    local templateStringTo = BuildingsTemplatesUtils:GetTemplateString(templateNameTo, campaignDatabase, selectorDB)

    if ( campaignDatabase ) then

        campaignDatabase:SetString(templateNameFrom, templateStringTo)

        campaignDatabase:SetString(templateNameTo, templateStringFrom)
    end

    if ( selectorDB ) then

        selectorDB:SetString(templateNameFrom, templateStringTo)

        selectorDB:SetString(templateNameTo, templateStringFrom)
    end

    self:FillMarkerMessage()
end

function buildings_swap_templates_tool:OnRelease()

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
        self.childEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_swap_templates_tool