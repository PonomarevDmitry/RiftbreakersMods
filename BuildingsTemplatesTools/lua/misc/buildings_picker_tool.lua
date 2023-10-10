local buildings_tool_base = require("lua/misc/buildings_tool_base.lua")
require("lua/utils/table_utils.lua")

class 'buildings_picker_tool' ( buildings_tool_base )

function buildings_picker_tool:__init()
    buildings_tool_base.__init(self,self)
end

function buildings_picker_tool:OnInit()

    self.marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_picker_tool_" .. self.marker

    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.templateEntities = {}

    self.template_name = self.data:GetString("template_name")

    self:FillMarkerMessage()

    self.previousMarkedRuins = {}
    -- Radius from player to highlight
    self.radiusShowRuins = 100.0
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

    local templateCaption = "gui/hud/building_templates/template_" .. self.marker

    local markerText = "${" .. templateCaption .. "}: "

    local buildingsIcons = self:GetTemplateBuildingsIcons(templateString)

    if ( string.len(buildingsIcons) > 0 ) then

        markerText = markerText .. buildingsIcons
    else

        markerText = markerText .. "${gui/hud/messages/buildings_tool_base/template_already_created}"
    end

    markerDB:SetString("message_text", markerText)
    markerDB:SetInt("message_visible", 1)
end

function buildings_picker_tool:AddedToSelection( entity )
end

function buildings_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
end

function buildings_picker_tool:OnUpdate()

    self:HighlightRuins()



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

    for entity in Iter( self.selectedEntities ) do

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

        ::continue::
    end

    for ruinEntity in Iter( ruinsList ) do

        local skinned = EntityService:IsSkinned( ruinEntity )
        if ( skinned ) then
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey_skinned", "selected")
        else
            EntityService:SetMaterial( ruinEntity, "selector/hologram_grey", "selected")
        end
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

        local database = EntityService:GetDatabase( ruinEntity )
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

        --local buildingDescHelper = reflection_helper( buildingDesc )

        local list = BuildingService:GetBuildCosts( blueprintName, self.playerId )

        if ( #list == 0 ) then
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
    self:HideMarkerMessage()
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

    -- Remove highlighting from ruins
    if ( self.previousMarkedRuins ~= nil) then

        for ruinEntity in Iter( self.previousMarkedRuins ) do
            EntityService:RemoveMaterial( ruinEntity, "selected" )
        end
    end
    self.previousMarkedRuins = {}

    if ( self.childEntity ~= nil) then
        EntityService:RemoveEntity(self.childEntity)
    end

    if ( buildings_tool_base.OnRelease ) then
        buildings_tool_base.OnRelease(self)
    end
end

return buildings_picker_tool