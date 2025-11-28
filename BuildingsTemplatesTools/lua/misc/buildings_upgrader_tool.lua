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

    self.numberFrom = 1
    self.numberTo = BuildingsTemplatesUtils:GetMaxAvailableTemplate()
    self.templateFormat = self.data:GetString("template_format")

    local markerBlueprint = "misc/marker_selector_buildings_upgrader_tool"
        -- Create new marker
    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    self.templateEntities = {}

    self.currentChildTemplate = ""

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:UpdateMarker()

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

function buildings_upgrader_tool:FillMarkerMessage()

    self:CleanInformationTemplateEntities()

    local templatesArray = self:GetTemplatesArray()

    self.selectedTemplate = self:CheckTemplateExists( self.selectedTemplate, templatesArray )

    self:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        local templatesStr = ""

        local allIsEmpty = true

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

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

                local markerText = "${gui/hud/messages/building_templates/templates_can_be_upgraded}:\n" .. templatesStr

                markerDB:SetString("message_text", markerText)
            else

                markerDB:SetString("message_text", "gui/hud/messages/building_templates/all_templates_upgraded")
            end
        end

        markerDB:SetInt("menu_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateUpgradeCaption = "gui/hud/building_templates/upgrade_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

        if ( templateString == "" ) then

            local markerText = "${" .. templateCaption .. "}:\n${gui/hud/messages/building_templates/empty_template}"

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
                        markerText = markerText .. "\n${gui/hud/messages/building_templates/can_be_upgraded}:\n" .. toUpgradeList
                    end
                else
                    markerText = "${" .. templateUpgradeCaption .. "}:\n" .. toUpgradeList
                end

                markerDB:SetString("message_text", markerText)
            end

            self:SpawnInformationBuildinsTemplates(templateString)
        end

        markerDB:SetInt("menu_visible", 1)
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

    local templatesArray = self:GetTemplatesArray()

    local currentTemplate = self:CheckTemplateExists( self.selectedTemplate, templatesArray )

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

    --local selectorDB = EntityService:GetOrCreateDatabase( self.selector )
    --selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:CheckTemplateExists( selectedTemplate, templatesArray )

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

function buildings_upgrader_tool:GetTemplatesArray()

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    local result = { self.allTemplatesName }

    if ( globalPlayerEntity ~= nil or selectorDB ~= nil or campaignDatabase ~= nil ) then

        for number=self.numberFrom,self.numberTo do

            local templateSuffix = string.format( "%02d", number )

            local templateName = self.templateFormat .. templateSuffix

            local templateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

            if ( templateString ~= nil and templateString ~= "" ) then

                if ( self:CanUpgradeTemplate(templateString) ) then

                    Insert( result, templateSuffix )
                end
            end
        end
    end

    return result
end

function buildings_upgrader_tool:OnActivateSelectorRequest()

    local globalPlayerEntity, selectorDB, campaignDatabase = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

    if ( globalPlayerEntity == nil and selectorDB == nil and campaignDatabase == nil ) then
        return
    end

    if ( self.selectedTemplate == self.allTemplatesName ) then

        for number=self.numberFrom,self.numberTo do

            local templateName = self.templateFormat .. string.format( "%02d", number )

            self:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, globalPlayerEntity, selectorDB, campaignDatabase)
        end
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        self:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, globalPlayerEntity, selectorDB, campaignDatabase)
    end

    self:FillMarkerMessage()
end

function buildings_upgrader_tool:UpgradeBlueprintsInTemplateAndSaveToDatabase(templateName, globalPlayerEntity, selectorDB, campaignDatabase)

    local currentTemplateString = BuildingsTemplatesUtils:GetTemplateString(templateName, globalPlayerEntity, selectorDB, campaignDatabase)
    if ( currentTemplateString == "" ) then
        return
    end

    local templateString = self:UpgradeBlueprintsInTemplate(currentTemplateString)

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetString( templateName, templateString )
        end

        if not ( is_server and is_client ) then

            local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. templateName .. "|" .. templateString

            QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
        end
    end

    if ( selectorDB ) then
        selectorDB:SetString( templateName, templateString )
    end

    if ( campaignDatabase ) then
        campaignDatabase:SetString( templateName, "" )
    end
end

function buildings_upgrader_tool:OnRelease()

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

return buildings_upgrader_tool