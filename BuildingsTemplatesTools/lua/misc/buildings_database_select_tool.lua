local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_database_select_tool' ( buildings_tool_base )

function buildings_database_select_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_database_select_tool:OnInit()

    self.scaleMap = {
        1,
    }

    self.modeCurrentDatabase = "current_database"

    self.selectedMode = self.modeCurrentDatabase

    self.numberFrom = self.data:GetInt("number_from")
    self.numberTo = self.data:GetInt("number_to")

    self.configName = "$buildings_database_select_config"

    local selectorDB = EntityService:GetDatabase( self.selector )

    self.selectedDatabaseNumber = selectorDB:GetIntOrDefault(self.configName, 1)

    self.markerMode = ""
    self.markerEntity = nil

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_select_tool:UpdateMarker()

    if ( self.markerMode ~= self.selectedMode or self.markerEntity == nil) then

        -- Destroy old marker
        if (self.markerEntity ~= nil) then

            EntityService:RemoveEntity(self.markerEntity)
            self.markerEntity = nil
        end

        local markerBlueprint = "misc/marker_selector_buildings_database_select_tool"-- .. self.selectedMode

        -- Create new marker
        self.markerEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

        -- Save number of wall layers
        self.markerMode = self.selectedMode
    end
end

function buildings_database_select_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.markerEntity )

    self.selectedMode = self:CheckTemplateExists(self.selectedMode)

    self:UpdateMarker()

    if ( self.selectedMode == self.modeCurrentDatabase ) then

        local databaseName = string.format( "%02d", self.selectedDatabaseNumber )

        local databaseCaption = "${gui/hud/building_templates/database_" .. databaseName .. "}"

        local markerText = "${gui/hud/building_templates/current_database}:\n" .. databaseCaption

        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("message_visible", 1)

    else

        local databaseCaption = "${gui/hud/building_templates/database_" .. self.selectedMode .. "}"

        local markerText = "${gui/hud/building_templates/select_database}:\n" .. databaseCaption

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("message_visible", 1)
    end
end

function buildings_database_select_tool:AddedToSelection( entity )
end

function buildings_database_select_tool:RemovedFromSelection( entity )
end

function buildings_database_select_tool:OnUpdate()
end

function buildings_database_select_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function buildings_database_select_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    local change = 1
    if ( degree > 0 ) then
        change = -1
    end

    local currentTemplate = self:CheckTemplateExists(self.selectedMode)

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

    self.selectedMode = newValue

    --local selectorDB = EntityService:GetDatabase( self.selector )
    --selectorDB:SetInt(self.configNameCellGaps, newValue)

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_select_tool:CheckTemplateExists( selectedTemplate )

    local templatesArray = self:GetTemplatesArray()

    selectedTemplate = selectedTemplate or templatesArray[1]

    local index = IndexOf( templatesArray, selectedTemplate )

    if ( index == nil ) then

        return templatesArray[1]
    end

    return selectedTemplate
end

function buildings_database_select_tool:GetTemplatesArray()

    local result = { self.modeCurrentDatabase }

    for number=self.numberFrom,self.numberTo do

        local databaseSuffix = string.format( "%02d", number )

        Insert( result, databaseSuffix )
    end

    return result
end

function buildings_database_select_tool:OnActivateSelectorRequest()

    if ( self.selectedMode == self.modeCurrentDatabase ) then

        return
    end

    local databaseNumber = tonumber(self.selectedMode)

    local selectorDB = EntityService:GetDatabase( self.selector )
    if ( selectorDB ) then
        selectorDB:SetInt(self.configName, databaseNumber)
    end

    self.selectedDatabaseNumber = databaseNumber

    self.selectedMode = self.modeCurrentDatabase
        
    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_select_tool:OnRelease()

    if ( self.markerEntity ~= nil) then
        EntityService:RemoveEntity(self.markerEntity)
        self.markerEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_select_tool