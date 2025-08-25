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

    self.modeCurrentDatabase = "current"

    self.selectedMode = self.modeCurrentDatabase

    self.numberFrom = self.data:GetInt("number_from")
    self.numberTo = self.data:GetInt("number_to")

    self.selectedDatabaseNumber = BuildingsTemplatesUtils:GetCurrentPersistentDatabase(self.selector)

    self.markerMode = ""

    local markerBlueprint = "misc/marker_selector_buildings_database_select_tool"
    self.markerEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_select_tool:UpdateMarker()

    if ( self.markerMode == self.selectedMode) then
        return
    end

    local markerBlueprint = ""

    if ( self.selectedMode == self.modeCurrentDatabase ) then

        if ( self.firstNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.firstNumberEntity)
            self.firstNumberEntity = nil
        end

        if ( self.secondNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.secondNumberEntity)
            self.secondNumberEntity = nil
        end

        if ( self.currentNumberEntity == nil) then

            markerBlueprint = "misc/marker_buildings_templates_numbers_current"

            self.currentNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
        end

    else

        if ( self.currentNumberEntity ~= nil) then
            EntityService:RemoveEntity(self.currentNumberEntity)
            self.currentNumberEntity = nil
        end

        local number = tonumber(self.selectedMode)

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

                EntityService:SetPosition( self.firstNumberEntity, 0, 0, 0.7 )
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

    self.markerMode = self.selectedTemplate
end

function buildings_database_select_tool:FillMarkerMessage()

    self.selectedMode = self:CheckTemplateExists(self.selectedMode)

    self:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.markerEntity )

    if ( self.selectedMode == self.modeCurrentDatabase ) then

        local databaseName = string.format( "%02d", self.selectedDatabaseNumber )

        local databaseCaption = "${gui/hud/building_templates/database_" .. databaseName .. "}"

        local markerText = "${gui/hud/building_templates/current_database}:\n" .. databaseCaption

        markerDB:SetString("message_text", markerText)
        markerDB:SetInt("menu_visible", 1)

    else

        local databaseCaption = "${gui/hud/building_templates/database_" .. self.selectedMode .. "}"

        local markerText = "${gui/hud/building_templates/select_database}:\n" .. databaseCaption

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("menu_visible", 1)
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

        if ( number ~= self.selectedDatabaseNumber ) then

            local databaseSuffix = string.format( "%02d", number )

            Insert( result, databaseSuffix )
        end
    end

    return result
end

function buildings_database_select_tool:OnActivateSelectorRequest()

    if ( self.selectedMode == self.modeCurrentDatabase ) then

        return
    end

    local databaseNumber = tonumber(self.selectedMode)

    BuildingsTemplatesUtils:SetCurrentPersistentDatabase(self.selector, databaseNumber)

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

    if ( self.firstNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.firstNumberEntity)
        self.firstNumberEntity = nil
    end

    if ( self.secondNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.secondNumberEntity)
        self.secondNumberEntity = nil
    end

    if ( self.currentNumberEntity ~= nil) then
        EntityService:RemoveEntity(self.currentNumberEntity)
        self.currentNumberEntity = nil
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_select_tool