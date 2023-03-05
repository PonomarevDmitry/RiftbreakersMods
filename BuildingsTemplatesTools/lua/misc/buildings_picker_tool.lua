local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'buildings_picker_tool' ( tool )

function buildings_picker_tool:__init()
    tool.__init(self,self)
end

function buildings_picker_tool:OnInit()

    local marker = self.data:GetString("marker")
    local markerBlueprint = "misc/marker_selector_buildings_picker_tool_" .. marker
    
    self.childEntity = EntityService:SpawnAndAttachEntity(markerBlueprint, self.entity)
    self.popupShown = false

    self.templateEntities = {}

    self.template_name = self.data:GetString("template_name")
end

function buildings_picker_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function buildings_picker_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function buildings_picker_tool:AddedToSelection( entity )
end

function buildings_picker_tool:OnUpdate()

    for entity in Iter( self.templateEntities ) do
        
        local skinned = EntityService:IsSkinned(entity)
        if ( skinned ) then
            EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
        else
            EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
        end 
    end

    for entity in Iter(self.selectedEntities ) do

        local skinned = EntityService:IsSkinned(entity)

        local isInList = IndexOf( self.templateEntities, entity ) == nil

        if ( isInList ) then
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_pass", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_pass", "selected")
            end
        else
            if ( skinned ) then
                EntityService:SetMaterial( entity, "selector/hologram_skinned_deny", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_deny", "selected")
            end
        end
    end
end

function buildings_picker_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function buildings_picker_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
end

function buildings_picker_tool:FindEntitiesToSelect( selectorComponent )

    local selectedItems = tool.FindEntitiesToSelect( self, selectorComponent )

    local position = selectorComponent.position
    
    local min = VectorSub(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    local max = VectorAdd(position, VectorMulByNumber(self.boundsSize , self.currentScale - 0.5))
    
    local ruins = FindService:FindEntitiesByGroupInBox( "##ruins##", min, max )

    for entity in Iter( self.selectedEntities ) do 
        if ( IndexOf( ruins, entity ) == nil and IndexOf( selectedItems, entity ) == nil ) then
            EntityService:RemoveMaterial( entity, "selected")
        end
    end
    
    for entity in Iter( ruins ) do
    
        if ( IndexOf( self.selectedEntities, entity ) == nil ) then
        
            if ( EntityService:IsSkinned( entity ) ) then
                EntityService:SetMaterial( entity, "selector/hologram_active_skinned", "selected")
            else
                EntityService:SetMaterial( entity, "selector/hologram_active", "selected")
            end

            if ( self.activated )  then
                self:OnActivateEntity( entity )
            end
        end
    end
    
    ConcatUnique( selectedItems, ruins)
    return selectedItems
end

function buildings_picker_tool:OnActivateEntity( entity )

    if ( IndexOf( self.templateEntities, entity ) == nil ) then

        Insert( self.templateEntities, entity )
    else

        Remove( self.templateEntities, entity )
    end

    self:SaveEntitiesToDatabase()
end

function buildings_picker_tool:SaveEntitiesToDatabase()

    -- templateString format:
    -- blueprint1:ent1PosX,ent1PosZ,ent1OrientX,ent1OrientY,ent1OrientZ,ent1OrientW;ent2PosX,ent2PosZ,ent2OrientX,ent2OrientY,ent2OrientZ,ent2OrientW|blueprint2:ent3PosX,ent3PosZ,ent3OrientX,ent3OrientY,ent3OrientZ,ent3OrientW;ent4PosX,ent4PosZ,ent4OrientX,ent4OrientY,ent4OrientZ,ent4OrientW

    -- Delimiter between blueprints groups: "|"
    -- Delimiter between blueprint name and array of entities coordinates: ":"
    -- Delimiter between entities in array of entities coordinates: ";"
    -- Delimiter between coordinates for single entity: ","
    -- blueprint1, blueprint2 - blueprints names
    -- ent1PosX, ent2PosX - entities relative position.x
    -- ent1PosZ, ent2PosZ - entities relative position.z

    -- ent1OrientX, ent2OrientX - entities orientation.x
    -- ent1OrientY, ent2OrientY - entities orientation.y
    -- ent1OrientZ, ent2OrientZ - entities orientation.z
    -- ent1OrientW, ent2OrientW - entities orientation.w
    
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

        local transform = EntityService:GetWorldTransform( entity )

        local position = transform.position
        local orientation = transform.orientation

        local deltaPositionX = position.x - startX
        local deltaPositionZ = position.z - startZ

        --local entityString = tostring(deltaPositionX)
        --entityString = entityString .. "," .. tostring(deltaPositionZ)

        --entityString = entityString .. "," .. tostring(orientation.x)
        --entityString = entityString .. "," .. tostring(orientation.y)
        --entityString = entityString .. "," .. tostring(orientation.z)
        --entityString = entityString .. "," .. tostring(orientation.w)

        local entityString = string.format(formatFloat, deltaPositionX)
        entityString = entityString .. "," .. string.format(formatFloat, deltaPositionZ)

        entityString = entityString .. "," .. string.format(formatFloat, orientation.x)
        entityString = entityString .. "," .. string.format(formatFloat, orientation.y)
        entityString = entityString .. "," .. string.format(formatFloat, orientation.z)
        entityString = entityString .. "," .. string.format(formatFloat, orientation.w)



        local entityBlueprint = EntityService:GetBlueprintName(entity)

        if ( hashBlueprints[entityBlueprint] == nil ) then
            
            Insert( listBlueprintsNames, entityBlueprint )

            hashBlueprints[entityBlueprint] = ""
        end

        local entitiesCoordinatesString = hashBlueprints[entityBlueprint]

        if ( string.len( entitiesCoordinatesString ) > 0 ) then

            entitiesCoordinatesString = entitiesCoordinatesString .. ";"
        end

        entitiesCoordinatesString = entitiesCoordinatesString .. entityString

        hashBlueprints[entityBlueprint] = entitiesCoordinatesString
    end

    local templateString = ""

    for entityBlueprint in Iter( listBlueprintsNames ) do

        local entitiesCoordinates = hashBlueprints[entityBlueprint]

        if ( string.len( templateString ) > 0 ) then

            templateString = templateString .. "|"
        end

        templateString = templateString .. entityBlueprint .. ":" .. entitiesCoordinates
    end

    LogService:Log("OnRelease self.template_name " .. self.template_name .. " templateString " .. templateString )

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

    tool.OnRelease(self)
end

return buildings_picker_tool
 