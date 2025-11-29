local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")
local TemplatesSerializeUtils = require("lua/misc/buildings_serialize_utils.lua")
local BuildingsTemplatesUtils = require("lua/misc/buildings_templates_utils.lua")

class 'buildings_picker_tool' ( buildings_tool_base )

function buildings_picker_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_picker_tool:OnInit()

    self.marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_picker_tool"

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)

    local number = tonumber(self.marker)
    local firstNumber = math.floor( number / 10 )
    local secondNumber = number % 10

    if ( firstNumber ~= 0 ) then
        markerBlueprint = "misc/marker_buildings_templates_numbers_" .. tostring(firstNumber) .. "x"
        self.firstNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)
    end

    markerBlueprint = "misc/marker_buildings_templates_numbers_x" .. tostring(secondNumber)
    self.secondNumberEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.selector)

    self.popupShown = false

    self.templateEntities = {}

    self.template_name = self.data:GetString("template_name")

    self:FillMarkerMessage()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
end

function buildings_picker_tool:FillMarkerMessage()

    local markerDB = EntityService:GetOrCreateDatabase( self.childEntity )

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)
    
    if ( globalPlayerEntity == nil and selectorDB == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/building_templates/database_unavailable")
        markerDB:SetInt("menu_visible", 1)
        return
    end

    self.currentTemplateString = BuildingsTemplatesUtils:GetTemplateString(self.template_name, globalPlayerEntity, selectorDB)

    if ( self.currentTemplateString == "" ) then

        markerDB:SetString("message_text", "")
        markerDB:SetInt("menu_visible", 0)
        return
    end

    local templateCaption = "gui/hud/building_templates/template_" .. self.marker

    local markerText = "${" .. templateCaption .. "}:\n"

    local buildingsIcons = self:GetTemplateBuildingsIcons(self.currentTemplateString)

    if ( string.len(buildingsIcons) > 0 ) then

        markerText = markerText .. buildingsIcons
    else

        markerText = markerText .. "${gui/hud/messages/buildings_tool_base/template_already_created}"
    end

    markerDB:SetString("message_text", markerText)
    markerDB:SetInt("menu_visible", 1)
end

function buildings_picker_tool:AddedToSelection( entity )
end

function buildings_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function buildings_picker_tool:OnUpdate()

    self.activated = self.activated or false

    self:HighlightRuins()

    

    self:ChangeFirstBuilding()

    local firstEntity = nil

    if ( #self.templateEntities > 0 ) then

        firstEntity = self.templateEntities[1]


        self:SetEntitySelectedMaterial( firstEntity, "hologram/current" )

        if ( #self.templateEntities > 1 ) then

            for i=2,#self.templateEntities do

                local entity = self.templateEntities[i]

                self:SetEntitySelectedMaterial( entity, "hologram/active" )
            end
        end
    end

    for entity in Iter( self.selectedEntities ) do

        local isInList = ( IndexOf( self.templateEntities, entity ) ~= nil )

        if ( isInList ) then

            if ( firstEntity ~= nil and entity ~= firstEntity ) then

                if ( self.activated == false ) then

                    -- Mark candidate to remove from template
                    self:SetEntitySelectedMaterial( entity, "hologram/deny" )
                end
            end
        else
            -- Mark candidate to add to template
            self:SetEntitySelectedMaterial( entity, "hologram/pass" )
        end
    end
end

function buildings_picker_tool:ChangeFirstBuilding()

    local maxDeltaTime = 2

    self.activated = self.activated or false

    if ( self.activated == false ) then
        return
    end

    self.changeFirstTime = self.changeFirstTime or 0

    if ( #self.selectedEntities ~= 1 or #self.templateEntities == 0 ) then
        self.changeFirstTime = 0
        self.changeFirstEntity = nil
        return
    end

    local entity = self.selectedEntities[1]

    if ( IndexOf( self.templateEntities, entity ) == nil ) then
        self.changeFirstTime = 0
        self.changeFirstEntity = nil
        return
    end

    local firstEntity = self.templateEntities[1]

    if ( entity == firstEntity ) then
        self.changeFirstTime = 0
        self.changeFirstEntity = nil
        return
    end

    local currentTime = GetLogicTime()

    if ( self.changeFirstEntity == entity ) then
        
        local deltaTime = currentTime - self.changeFirstTime

        if ( deltaTime >= maxDeltaTime ) then

            self.changeFirstTime = 0
            self.changeFirstEntity = nil

            local indexEntity = IndexOf( self.templateEntities, entity )

            self.templateEntities[1] = entity
            self.templateEntities[indexEntity] = firstEntity

            self:SaveEntitiesToDatabase()
        end
    else
        
        self.changeFirstTime = currentTime
        self.changeFirstEntity = entity
    end
end

function buildings_picker_tool:HighlightRuins()

    local ruinsList = self:FindBuildingRuins()

    self.previousMarkedRuins = self.previousMarkedRuins or {}

    -- Remove highlighting from previous ruins
    for ruinEntity in Iter( self.previousMarkedRuins ) do

        -- If the ruin is not included in the new list
        if ( IndexOf( ruinsList, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.templateEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        EntityService:RemoveMaterial( ruinEntity, "selected" )
        local children = EntityService:GetChildren( ruinEntity, true )
        for child in Iter( children ) do
            EntityService:RemoveMaterial( child, "selected" )
        end

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        self:SetEntitySelectedMaterial( ruinEntity, "hologram/grey" )
    end

    self.previousMarkedRuins = ruinsList
end

function buildings_picker_tool:FindBuildingRuins()

    local player = PlayerService:GetPlayerControlledEnt(self.playerId)

    local ruinsList = FindService:FindEntitiesByGroupInRadius( player, "##ruins##", self.radiusShowRuins )

    local result = {}

    for ruinEntity in Iter( ruinsList ) do

        if ( IndexOf( result, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.selectedEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        if ( IndexOf( self.templateEntities, ruinEntity ) ~= nil ) then
            goto continue
        end

        local database = EntityService:GetOrCreateDatabase( ruinEntity )
        if ( database == nil ) then
            goto continue
        end

        if ( not database:HasString("blueprint") ) then
            goto continue
        end

        local ruinsBlueprint = database:GetString("blueprint")
        if ( not ResourceManager:ResourceExists( "EntityBlueprint", ruinsBlueprint ) ) then
            goto continue
        end

        Insert( result, ruinEntity )

        ::continue::
    end

    return result
end

function buildings_picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = buildings_tool_base.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local boundsSize = { x=1.0, y=100.0, z=1.0 }

    local scaleVector = VectorMulByNumber(boundsSize, self.currentScale)

    local min = VectorSub(position, scaleVector)
    local max = VectorAdd(position, scaleVector)

    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    ruins = self:FilterSelectedEntities( ruins )

    ConcatUnique( selectedItems, ruins )

    return selectedItems
end

function buildings_picker_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = self:GetBlueprintName( entity )

        if ( blueprintName == "" ) then
            goto continue
        end

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local buildingDescRef = reflection_helper( buildingDesc )
        if ( buildingDescRef.build_cost == nil or buildingDescRef.build_cost.resource == nil or buildingDescRef.build_cost.resource.count == nil or buildingDescRef.build_cost.resource.count <= 0 ) then
            goto continue
        end

        if ( not BuildingService:IsBuildingAvailable( self.playerId, blueprintName ) ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function buildings_picker_tool:GetBlueprintName( entity )

    local blueprintName = EntityService:GetBlueprintName( entity )

    if( EntityService:GetGroup( entity ) == "##ruins##" ) then

        local database = EntityService:GetOrCreateDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function buildings_picker_tool:OnActivateSelectorRequest()

    self.activated = true

    self:ClearTemplate()

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity, true, true )
    end

    self:SaveEntitiesToDatabase()
    self:HideMarkerMessage()
end

function buildings_picker_tool:ClearTemplate()

    if ( self.currentTemplateString == "" ) then

        self.clickCount = 0
        self.clickLastTime = 0
        return
    end

    self.clickCount = self.clickCount or 0
    self.clickLastTime = self.clickLastTime or 0

    if ( #self.selectedEntities ~= 0 ) then

        self.clickCount = 0
        self.clickLastTime = 0
        return
    end

    local maxDeltaTime = 0.5
    local maxClicksToClear = 5

    local currentTime = GetLogicTime()

    if ( self.templateEntities == nil or #self.templateEntities == 0 ) then

        local deltaFromLast = currentTime - self.clickLastTime

        if ( deltaFromLast < maxDeltaTime ) then

            self.clickCount = self.clickCount + 1
        else

            self.clickCount = 0
            self.clickLastTime = 0
        end

        if ( self.clickCount >= maxClicksToClear ) then

            if( self.popupShown == false ) then

                self.popupShown = true

                self:RegisterHandler(self.entity, "GuiPopupResultEvent", "OnGuiPopupResultEvent")

                GuiService:OpenPopup(self.entity, "gui/popup/popup_ingame_2buttons", "gui/hud/messages/building_templates/clear_template_confirm")

                self.clickCount = 0
                self.clickLastTime = 0
            end
        end
    end

    self.clickLastTime = currentTime
end

function buildings_picker_tool:OnGuiPopupResultEvent( evt )

    self:UnregisterHandler( evt:GetEntity(), "GuiPopupResultEvent", "OnGuiPopupResultEvent" )

    self.clickCount = 0
    self.clickLastTime = 0

    self.popupShown = false

    if ( evt:GetResult() == "button_yes" ) then

        self:HideMarkerMessage()

        self.currentTemplateString = ""

        local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)

        if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

            local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

            if ( globalPlayerEntityDB ) then
                globalPlayerEntityDB:SetString( self.template_name, "" )
            end

            if not ( is_server and is_client ) then

                local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. self.template_name .. "|"

                QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
            end
        end

        if ( selectorDB ) then
            selectorDB:SetString( self.template_name, "" )
        end

        if ( CampaignService.GetCampaignData ~= nil ) then

            local campaignDatabase = CampaignService:GetCampaignData()

            if ( campaignDatabase and campaignDatabase:HasString( self.template_name ) ) then

                campaignDatabase:RemoveKey( self.template_name )
            end
        end
    end
end

function buildings_picker_tool:OnActivateEntity( entity, removalEnabled, ignoreSaveToDatabase )

    removalEnabled = removalEnabled or false
    ignoreSaveToDatabase = ignoreSaveToDatabase or false

    if ( IndexOf( self.templateEntities, entity ) == nil ) then

        Insert( self.templateEntities, entity )
    elseif ( removalEnabled ) then

        Remove( self.templateEntities, entity )
    end

    if ( not ignoreSaveToDatabase ) then
        self:SaveEntitiesToDatabase()
        self:HideMarkerMessage()
    end
end

function buildings_picker_tool:SaveEntitiesToDatabase()

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

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

    if ( self.templateEntities == nil or #self.templateEntities == 0 ) then
        return
    end

    local globalPlayerEntity, selectorDB = BuildingsTemplatesUtils:GetTemplatesDatabases(self.selector)
    
    if ( globalPlayerEntity == nil and selectorDB == nil ) then
        return
    end

    local firstEntity = self.templateEntities[1]

    local firstPosition = EntityService:GetPosition( firstEntity )

    local startX = firstPosition.x
    local startZ = firstPosition.z

    local hashBlueprints = {}
    local listBlueprintsNames = {}

    local formatFloat = "%g"

    for entity in Iter( self.templateEntities ) do

        local entityBlueprint = self:GetBlueprintName( entity )

        if ( hashBlueprints[entityBlueprint] == nil ) then

            Insert( listBlueprintsNames, entityBlueprint )

            hashBlueprints[entityBlueprint] = {}
        end

        local entitiesCoordinatesStringArray = hashBlueprints[entityBlueprint]



        local transform = EntityService:GetWorldTransform( entity )

        local position = transform.position
        local orientation = transform.orientation

        local deltaPositionX = position.x - startX
        local deltaPositionZ = position.z - startZ

        --local entityString = tostring(deltaPositionX)
        --entityString = entityString .. delimiterBetweenCoordinates .. tostring(deltaPositionZ)

        --entityString = entityString .. delimiterBetweenCoordinates .. tostring(orientation.y)
        --entityString = entityString .. delimiterBetweenCoordinates .. tostring(orientation.w)

        --local entityString = string.format(formatFloat, deltaPositionX)
        --entityString = entityString .. delimiterBetweenCoordinates .. string.format(formatFloat, deltaPositionZ)

        --entityString = entityString .. delimiterBetweenCoordinates .. string.format(formatFloat, orientation.y)
        --entityString = entityString .. delimiterBetweenCoordinates .. string.format(formatFloat, orientation.w)

        if ( #entitiesCoordinatesStringArray > 0 ) then
            Insert( entitiesCoordinatesStringArray, delimiterEntitiesArray )
        end

        Insert( entitiesCoordinatesStringArray, string.format(formatFloat, deltaPositionX) )
        Insert( entitiesCoordinatesStringArray, delimiterBetweenCoordinates )

        Insert( entitiesCoordinatesStringArray, string.format(formatFloat, deltaPositionZ) )
        Insert( entitiesCoordinatesStringArray, delimiterBetweenCoordinates )

        Insert( entitiesCoordinatesStringArray, string.format(formatFloat, orientation.y) )
        Insert( entitiesCoordinatesStringArray, delimiterBetweenCoordinates )

        Insert( entitiesCoordinatesStringArray, string.format(formatFloat, orientation.w) )

        local databaseInfo = self:GetDatabaseInfo(entity)
        if ( databaseInfo ~= "" ) then
            Insert( entitiesCoordinatesStringArray, delimiterBetweenCoordinates )
            Insert( entitiesCoordinatesStringArray, databaseInfo )
        end
    end

    local templateStringArray = {}

    for entityBlueprint in Iter( listBlueprintsNames ) do

        if ( #templateStringArray > 0 ) then
            Insert( templateStringArray, delimiterBlueprintsGroups )
        end

        Insert( templateStringArray, entityBlueprint )
        Insert( templateStringArray, delimiterBlueprintName )

        local entitiesCoordinates = hashBlueprints[entityBlueprint]

        for str in Iter( entitiesCoordinates ) do
            Insert( templateStringArray, str )
        end
    end

    local templateString = table.concat( templateStringArray )

    if ( globalPlayerEntity ~= nil and globalPlayerEntity ~= INVALID_ID ) then

        local globalPlayerEntityDB = EntityService:GetDatabase( globalPlayerEntity )

        if ( globalPlayerEntityDB ) then
            globalPlayerEntityDB:SetString( self.template_name, templateString )
        end

        if not ( is_server and is_client ) then

            local mapperName = "SetGlobalPlayerEntityDatabaseString|" .. self.template_name .. "|" .. templateString

            QueueEvent("OperateActionMapperRequest", globalPlayerEntity, mapperName, false )
        end
    end

    if ( selectorDB ) then
        selectorDB:SetString( self.template_name, templateString )
    end

    if ( CampaignService.GetCampaignData ~= nil ) then

        local campaignDatabase = CampaignService:GetCampaignData()

        if ( campaignDatabase and campaignDatabase:HasString( self.template_name ) ) then

            campaignDatabase:RemoveKey( self.template_name )
        end
    end


    self.currentTemplateString = templateString

    --LogService:Log("templateString " .. templateString)
end

function buildings_picker_tool:GetDatabaseInfo(entity)

    local database = EntityService:GetOrCreateDatabase( entity )
    if ( database == nil ) then
        return ""
    end

    local targetEntityLowNameKeyPrefix = BuildingService:FindLowUpgrade( EntityService:GetBlueprintName(entity) ) .. "_"

    local databaseStringValues = nil
    local databaseFloatValues = nil
    local databaseIntValues = nil
    local databaseVectorValues = nil

    local stringKeys = database:GetStringKeys()
    for key in Iter( stringKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            databaseStringValues = databaseStringValues or {}
            databaseStringValues[key] = database:GetString(key)
        end
    end

    local floatKeys = database:GetFloatKeys()
    for key in Iter( floatKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            databaseFloatValues = databaseFloatValues or {}
            databaseFloatValues[key] = database:GetFloat(key)
        end
    end

    local intKeys = database:GetIntKeys()
    for key in Iter( intKeys ) do

        local stringNumber = string.find( key, targetEntityLowNameKeyPrefix )
        if ( stringNumber == 1 ) then
            databaseIntValues = databaseIntValues or {}
            databaseIntValues[key] = database:GetInt(key)
        end
    end

    local keyVector = targetEntityLowNameKeyPrefix .. "center_point_vector"
    if ( database:HasVector(keyVector) ) then
        databaseVectorValues = databaseVectorValues or {}
        databaseVectorValues[keyVector] = database:GetVector(keyVector)
    end

    if ( databaseStringValues or databaseFloatValues or databaseIntValues or databaseVectorValues ) then

        local result = {}
        result.databaseStringValues = databaseStringValues
        result.databaseFloatValues = databaseFloatValues
        result.databaseIntValues = databaseIntValues
        result.databaseVectorValues = databaseVectorValues

        local result = TemplatesSerializeUtils:SerializeObject( result )

        --LogService:Log("result " .. result)

        return result
    else
        return ""
    end
end

function buildings_picker_tool:OnRelease()

    self:SaveEntitiesToDatabase()

    if ( self.templateEntities ~= nil) then
        for entity in Iter( self.templateEntities ) do
            self:RemovedFromSelection( entity )
        end
    end

    self.templateEntities = {}

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do
            EntityService:RemoveMaterial( ruinEntity, "selected" )
            local children = EntityService:GetChildren( ruinEntity, true )
            for child in Iter( children ) do
                EntityService:RemoveMaterial( child, "selected" )
            end
        end
    end
    self.previousMarkedRuins = {}

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

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_picker_tool