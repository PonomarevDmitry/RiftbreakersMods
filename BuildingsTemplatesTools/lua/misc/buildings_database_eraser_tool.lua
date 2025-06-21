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

    self.numberFrom = 1
    self.numberTo = BuildingsTemplatesUtils:GetMaxAvailableTemplate()
    self.templateFormat = self.data:GetString("template_format")

    local selectedDatabaseNumber = BuildingsTemplatesUtils:GetCurrentPersistentDatabase(self.selector)
    self.selectedDatabaseCaption = "${gui/hud/building_templates/database_" .. string.format( "%02d", selectedDatabaseNumber ) .. "}"

    self.persistentDatabase = BuildingsTemplatesUtils:GetPersistentDatabase(selectedDatabaseNumber)

    self.currentChildTemplate = ""

    local markerBlueprint = "misc/marker_selector_buildings_database_eraser_tool"
    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    self.templateEntities = {}

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_eraser_tool:UpdateMarker()

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

function buildings_database_eraser_tool:FillMarkerMessage()

    self:CleanTemplateEntities()

    self.selectedTemplate = self:CheckTemplateExists(self.selectedTemplate)

    self:UpdateMarker()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    if ( self.persistentDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

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

        markerDB:SetInt("menu_visible", 1)

    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local templateEraseCaption = "gui/hud/building_templates/erase_persistent_template_" .. self.selectedTemplate

        local templateCaption = "gui/hud/building_templates/template_" .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""

        if ( persistentTemplateString == "" ) then

            markerText = markerText .. "${" .. templateCaption .. "}:\n${gui/hud/messages/building_templates/empty_template}"
        else

            local buildingsIcons = self:GetTemplateBuildingsIcons(persistentTemplateString)

            markerText = markerText .. "${" .. templateEraseCaption .. "}:\n" .. buildingsIcons

            self:SpawnBuildinsTemplates(persistentTemplateString)
        end

        markerDB:SetString("message_text", markerText)

        markerDB:SetInt("menu_visible", 1)
    end
end

function buildings_database_eraser_tool:SpawnBuildinsTemplates(templateString)

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


    local team = EntityService:GetTeam( self.entity )

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    -- Split by "|" blueprints groups
    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

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

        --if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
        --    goto continue
        --end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef == nil ) then
            goto continue
        end

        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto continue
        end

        local buildCosts = BuildingService:GetBuildCosts( blueprintName, self.playerId )
        --if ( #buildCosts == 0 ) then
        --    goto continue
        --end

        -- Do not create cubes for building_mode "line"
        local createCube = not ( buildingDescRef.building_mode == "line" )

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )

        for entityString in Iter( entitiesCoordinatesArray ) do

            self:CreateSingleBuildingTemplate( blueprintName, buildingDescRef, createCube, entityString, buildCosts, delimiterBetweenCoordinates )
        end

        ::continue::
    end

    if ( #self.templateEntities > 0 ) then

        if ( #self.templateEntities > 1 ) then

            for i=2,#self.templateEntities do

                local buildingTemplate = self.templateEntities[i]

                if ( EntityService:HasComponent( buildingTemplate.entity, "DisplayRadiusComponent" ) ) then

                    EntityService:RemoveComponent( buildingTemplate.entity, "DisplayRadiusComponent" )
                end

                if ( EntityService:HasComponent( buildingTemplate.entity, "GhostLineCreatorComponent" ) ) then

                    EntityService:RemoveComponent( buildingTemplate.entity, "GhostLineCreatorComponent" )
                end
            end
        end

        local firstBuildingTemplate = self.templateEntities[1]
        local firstEntity = firstBuildingTemplate.entity

        local gridSize = BuildingService:GetBuildingGridSize( firstEntity )

        self.currentScale = math.max(gridSize.x, gridSize.z)
        EntityService:SetScale( self.entity, gridSize.x, 1, gridSize.z )
    end

    self:SetChildrenPosition()
    self:RescaleChild()
end

function buildings_database_eraser_tool:CreateSingleBuildingTemplate( blueprintName, buildingDesc, createCube, entityString, buildCosts, delimiterBetweenCoordinates )

    -- Split coordinates by ","
    local valuesArray = Split( entityString, delimiterBetweenCoordinates )

    -- Only 4 values in valuesArray
    if ( #valuesArray < 4 ) then
        return
    end

    local positionX = tonumber( valuesArray[1] )
    local positionZ = tonumber( valuesArray[2] )

    local orientationY = tonumber( valuesArray[3] )
    local orientationW = tonumber( valuesArray[4] )

    -- Parse to number successful
    if ( positionX == nil or positionZ == nil or orientationY == nil or orientationW == nil ) then
        return
    end

    local databaseInfo = valuesArray[5]

    local buildingTemplate = {}

    buildingTemplate.blueprint = blueprintName
    buildingTemplate.databaseInfo = databaseInfo

    buildingTemplate.buildingDesc = buildingDesc
    buildingTemplate.createCube = createCube

    buildingTemplate.positionX = positionX
    buildingTemplate.positionZ = positionZ

    local orientation = {}

    orientation.x = 0
    orientation.y = orientationY
    orientation.z = 0
    orientation.w = orientationW

    buildingTemplate.orientation = orientation

    local newPosition = {}

    newPosition.x = positionX
    newPosition.y = 0
    newPosition.z = positionZ

    local buildingEntity = nil

    if ( buildingDesc.ghost_bp ~= "" and buildingDesc.ghost_bp ~= nil ) then

        buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.ghost_bp, self.selector )
    else
        buildingEntity = EntityService:SpawnAndAttachEntity( buildingDesc.bp, self.selector )
    end

    EntityService:RemoveComponent( buildingEntity, "LuaComponent" )

    EntityService:SetPosition( buildingEntity, newPosition )
    EntityService:SetOrientation( buildingEntity, orientation )

    self:ChangeEntityMaterial( buildingEntity, "hologram/blue" )

    buildingTemplate.entity = buildingEntity

    Insert( self.templateEntities, buildingTemplate )
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

    self:UpdateMarker()

    self:FillMarkerMessage()
end

function buildings_database_eraser_tool:CheckTemplateExists( selectedTemplate )

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

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/clear_all_templates_confirm")
    else

        local templateName = self.templateFormat .. self.selectedTemplate

        local persistentTemplateString = self.persistentDatabase:GetStringOrDefault( templateName, "" ) or ""
        if ( persistentTemplateString == "" ) then
            return
        end

        self.templateNameForErase = templateName

        self.popupShown = true

        self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEventSingleTemplate")

        GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/clear_template_confirm")
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

    self.persistentDatabase:SetString( self.templateNameForErase, "" )

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

function buildings_database_eraser_tool:CleanTemplateEntities()

    for buildingTemplate in Iter(self.templateEntities) do

        EntityService:RemoveEntity(buildingTemplate.entity)
        buildingTemplate.entity = nil
    end

    self.templateEntities = {}

    self.currentScale = 1
    EntityService:SetScale( self.entity, 1, 1, 1 )

    self:SetChildrenPosition()
    self:RescaleChild()
end

function buildings_database_eraser_tool:OnRelease()

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

    self:CleanTemplateEntities()

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_database_eraser_tool