local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'buildings_picker_tool' ( tool )

function buildings_picker_tool:__init()
    tool.__init(self,self)
end

function buildings_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function buildings_picker_tool:OnInit()

    local marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_picker_tool_" .. marker

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.templateEntities = {}

    self.template_name = self.data:GetString("template_name")

    self:FillMarkerMessage()
end

function buildings_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function buildings_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function buildings_picker_tool:HideMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    markerDB:SetString("message_text", "")
    markerDB:SetInt("message_visible", 0)
end

function buildings_picker_tool:FillMarkerMessage()

    local markerDB = EntityService:GetDatabase( self.childEntity )

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/database_unavailable")
        markerDB:SetInt("message_visible", 1)
        return
    end

    local templateString = campaignDatabase:GetStringOrDefault( self.template_name, "" ) or ""

    if ( templateString == "" ) then

        markerDB:SetString("message_text", "")
        markerDB:SetInt("message_visible", 0)
        return
    end

    local delimiterBlueprintsGroups = "|";
    local delimiterBlueprintName = ":";
    local delimiterEntitiesArray = ";";
    local delimiterBetweenCoordinates = ",";

    local blueprintsGroupsArray = Split( templateString, delimiterBlueprintsGroups )

    local listIconsNames = {}
    local hashIconsCount = {}

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

        local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( blueprintBuildingDesc == nil ) then
            goto continue
        end

        local buildingDesc = reflection_helper( blueprintBuildingDesc )
        if ( buildingDesc == nil ) then
            goto continue
        end

        local menuIcon = buildingDesc.menu_icon or ""

        if ( menuIcon == "" ) then

            for i=1,buildingDesc.connect.count do

                local connectRecord = buildingDesc.connect[i]

                for j=1,connectRecord.value.count do

                    local connectBlueprintName = connectRecord.value[j]

                    local connectMenuIcon = self:GetBuildingMenuIcon( connectBlueprintName )

                    if ( connectMenuIcon ~= "" ) then
                        menuIcon = connectMenuIcon
                        goto icon_found
                    end
                end
            end
        end

        ::icon_found::

        if ( menuIcon == "" ) then
            goto continue
        end

        -- Split array of coordinates by ";"
        local entitiesCoordinatesArray = Split( entitiesCoordinatesString, delimiterEntitiesArray )
        if ( #entitiesCoordinatesArray > 0) then

            if ( hashIconsCount[menuIcon] == nil ) then

                Insert( listIconsNames, menuIcon )

                hashIconsCount[menuIcon] = 0
            end

            hashIconsCount[menuIcon] = hashIconsCount[menuIcon] + #entitiesCoordinatesArray
        end

        ::continue::
    end

    local markerText = ""

    for menuIcon in Iter( listIconsNames ) do

        local count = hashIconsCount[menuIcon]

        if ( count > 0 ) then

            if ( string.len(markerText) > 0 ) then

                markerText = markerText .. ", "
            end

            markerText = markerText .. '<img="' .. menuIcon .. '"> ' .. tostring(count)
        end
    end

    if ( string.len(markerText) > 0 ) then

        markerDB:SetString("message_text", markerText)
    else

        markerDB:SetString("message_text", "gui/hud/messages/buildings_picker_tool/template_already_created")
    end

    markerDB:SetInt("message_visible", 1)
end

function buildings_picker_tool:GetBuildingMenuIcon( blueprintName )

    if ( not ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then
        return ""
    end

    local blueprintBuildingDesc = BuildingService:GetBuildingDesc( blueprintName )
    if ( blueprintBuildingDesc == nil ) then
        return ""
    end

    local buildingDesc = reflection_helper( blueprintBuildingDesc )
    if ( buildingDesc == nil ) then
        return ""
    end

    local menuIcon = buildingDesc.menu_icon or ""

    return menuIcon
end

function buildings_picker_tool:AddedToSelection( entity )
end

function buildings_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function buildings_picker_tool:OnUpdate()

    local firstEntity = nil

    if ( #self.templateEntities > 0 ) then

        firstEntity = self.templateEntities[1]

        local skinned = EntityService:IsSkinned(firstEntity)
        if ( skinned ) then
            EntityService:SetMaterial( firstEntity, "selector/hologram_current_skinned", "selected")
        else
            EntityService:SetMaterial( firstEntity, "selector/hologram_current", "selected")
        end

        if ( #self.templateEntities > 1 ) then

            for i=2,#self.templateEntities do

                local entity = self.templateEntities[i]

                local skinned = EntityService:IsSkinned(entity)
                if ( skinned ) then
                    EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
                else
                    EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
                end
            end
        end
    end

    for entity in Iter(self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        local isInList = ( IndexOf( self.templateEntities, entity ) ~= nil )

        if ( isInList ) then

            if ( firstEntity ~= nil and entity ~= firstEntity ) then

                -- Mark candidate to remove from template
                if ( skinned ) then
                    EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
                else
                    EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
                end
            end
        else
            -- Mark candidate to add to template
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        end
    end
end

function buildings_picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position

    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))

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

        --local buildingDescHelper = reflection_helper( buildingDesc )

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )

        if ( #list == 0 ) then
            goto continue
        end

        if ( not BuildingService:IsBuildingAvailable( blueprintName ) ) then
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

        local database = EntityService:GetDatabase( entity )

        if ( database and database:HasString("blueprint") ) then

            blueprintName = database:GetString("blueprint")
        end
    end

    blueprintName = blueprintName or ""

    return blueprintName
end

function buildings_picker_tool:OnActivateSelectorRequest()

    self.activated = true

    if ( #self.selectedEntities == 0 ) then
        return
    end

    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity, true, true )
    end

    self:SaveEntitiesToDatabase()
    self:HideMarkerMessage( false )
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

    local campaignDatabase = CampaignService:GetCampaignData()
    if ( campaignDatabase == nil ) then
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

    --LogService:Log("OnRelease self.template_name " .. self.template_name .. " templateString " .. templateString )

    campaignDatabase:SetString( self.template_name, templateString )
end

function buildings_picker_tool:OnRelease()

    self:SaveEntitiesToDatabase()

    if ( self.templateEntities ~= nil) then
        for entity in Iter( self.templateEntities ) do
            self:RemovedFromSelection( entity )
        end
    end

    self.templateEntities = {}

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
    end

    if ( tool.OnRelease ) then
        tool.OnRelease(self)
    end
end

return buildings_picker_tool