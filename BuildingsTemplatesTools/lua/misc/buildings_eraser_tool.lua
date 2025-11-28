local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_eraser_tool' ( buildings_tool_base )

function buildings_eraser_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_eraser_tool:OnInit()

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

    self.currentChildTemplate = ""

    local markerBlueprint = "misc/marker_selector_buildings_eraser_tool"
    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    self.templateEntities = {}

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_eraser_tool:UpdateMarker()

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

            self.allNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)
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

                self.firstNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)
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

            self.secondNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)
        end
    end

    self.currentChildTemplate = self.selectedTemplate
end

function buildings_eraser_tool:FillMarkerMessage()

    self:CleanInformationTemplateEntities()

    self.selectedTemplate = self:CheckTemplateExists(self.selectedTemplate)

    self:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    local markerText = ""

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

            if ( templateString ~= nil and templateString ~= "" ) then

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

        markerDB:SetInt("menu_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateEraseCaption = "gui/hud/building_templates/erase_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

        if ( templateString == "" ) then

            markerText = markerText .. "${" .. templateCaption .. "}:\n${gui/hud/messages/building_templates/empty_template}"
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

            markerText = markerText .. "${" .. templateEraseCaption .. "}:\n" .. buildingsIcons

            self:SpawnInformationBuildinsTemplates(templateString)
        end

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("menu_visible", 1)
    end
end

function buildings_eraser_tool:AddedToSelection( entity )
end

function buildings_eraser_tool:RemovedFromSelection( entity )
end

function buildings_eraser_tool:OnUpdate()
end

function buildings_eraser_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_eraser_tool:OnRotateSelectorRequest(evt)

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

function buildings_eraser_tool:CheckTemplateExists( selectedTemplate )

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

function buildings_eraser_tool:GetTemplatesArray()

    local result = { self.allTemplatesName }

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity ~= nil or selectorDB ~= nil or campaignDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

            if ( templateString ~= nil and templateString ~= "" ) then

                Insert( result, templateSuffix )
            end
        end
    end

    return result
end

function buildings_eraser_tool:OnActivateSelectorRequest()

    if( self.popupShown ) then

        return
    end

    if ( self.timeoutTime ~= nil and self.timeoutTime > GetLogicTime() ) then
        return
    end

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        if ( not self:DatabaseHasTemplate(globalPlayerEntity, selectorDB, campaignDatabase) ) then
            return
        end

        self.popupShown = true

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates")

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/clear_all_templates_confirm")
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)
        if ( templateString == "" ) then
            return
        end

        self.templateNameForErase = templateName

        self.popupShown = true

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate")

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/clear_template_confirm")
    end
end

function buildings_eraser_tool:DatabaseHasTemplate(globalPlayerEntity, selectorDB, campaignDatabase)

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

        if ( templateString ~= nil and templateString ~= "" ) then

            return true
        end
    end

    return false
end

function buildings_eraser_tool:SaveTimeout()

    local cooldown = 1

    self.timeoutTime = GetLogicTime() + cooldown
end

function buildings_eraser_tool:OnGuiPopupResultEventSingleTemplate( evt )

    self:SaveTimeout()

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate" )

    if ( evt:GetResult() ~= "button_yes" ) then
        self.popupShown = false
        return
    end

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        return
    end

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        if ( is_server and is_client ) then

            local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

            if ( globalPlayerEntityDB ) then
                globalPlayerEntityDB:SetString( self.templateNameForErase, "" )
            end
        else

            local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

            if ( globalPlayerEntityDB ) then
                globalPlayerEntityDB:SetString( self.templateNameForErase, "" )
            end

            local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. self.templateNameForErase .. "|"

            QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
        end
    end

    if ( selectorDB ) then
        selectorDB:SetString( self.templateNameForErase, "" )
    end

    if ( campaignDatabase ) then
        campaignDatabase:SetString( self.templateNameForErase, "" )
    end

    self:UpdateMarker()

    self:FillMarkerMessage()

    self.popupShown = false
end

function buildings_eraser_tool:OnGuiPopupResultEventAllTemplates( evt )

    self:SaveTimeout()

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEventAllTemplates" )

    if ( evt:GetResult() ~= "button_yes" ) then
        self.popupShown = false
        return
    end

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        return
    end

    for number=self.numberFrom,self.numberTo do

        local templateName = self.templateFormat .. string.format( "%02d", number )

        if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

            if ( is_server and is_client ) then

                local globalPlayerEntityDB = EntityService:GetOrCreateDatabase( globalPlayerEntity )

                if ( globalPlayerEntityDB ) then
                    globalPlayerEntityDB:SetString( templateName, "" )
                end
            else

                local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

                if ( globalPlayerEntityDB ) then
                    globalPlayerEntityDB:SetString( templateName, "" )
                end

                local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. templateName .. "|"

                QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
            end
        end

        if ( selectorDB ) then
            selectorDB:SetString( templateName, "" )
        end

        if ( campaignDatabase ) then
            campaignDatabase:SetString( templateName, "" )
        end
    end

    self:UpdateMarker()

    self:FillMarkerMessage()

    self.popupShown = false
end

function buildings_eraser_tool:OnRelease()

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

return buildings_eraser_tool