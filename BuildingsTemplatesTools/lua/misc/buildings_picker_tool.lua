local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'buildings_picker_tool' ( tool )

function buildings_picker_tool:__init()
    tool.__init(self,self)
end

function buildings_picker_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_buildings_picker_tool", self.entity)
    self.popupShown = false

    self.templateEntities = {}
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
end

function buildings_picker_tool:OnRelease()
    
    if ( self.templateEntities ~= nil) then

        if ( #self.templateEntities > 0 ) then

            local templateString = ""

            local firstEntity = self.templateEntities[1]

            local firstPosition = EntityService:GetPosition( firstEntity )

            local startX = firstPosition.x
            local startZ = firstPosition.z

            for entity in Iter( self.templateEntities ) do

                if ( string.len( templateString ) > 0 ) then

                    templateString = templateString .. "|"
                end

                local transform = EntityService:GetWorldTransform( entity )

                local position = transform.position
                local orientation = transform.orientation

                local entityBlueprint = EntityService:GetBlueprintName(entity)

                local deltaPositionX = position.x - startX
                local deltaPositionZ = position.z - startZ

                local entityString = entityBlueprint

                entityString = entityString .. "," .. tostring(deltaPositionX)
                entityString = entityString .. "," .. tostring(deltaPositionZ)

                entityString = entityString .. "," .. tostring(orientation.x)
                entityString = entityString .. "," .. tostring(orientation.y)
                entityString = entityString .. "," .. tostring(orientation.z)
                entityString = entityString .. "," .. tostring(orientation.w)

                LogService:Log("OnRelease entityString " .. entityString )

                templateString = templateString .. entityString
            end

            local campaignDatabase = CampaignService:GetCampaignData()

            if ( campaignDatabase ~= nil ) then

                LogService:Log("OnRelease templateString " .. templateString )

                campaignDatabase:SetString( "", templateString )
            end
        end

        for entity in Iter( self.templateEntities ) do
            self:RemovedFromSelection( entity )
        end
    end
    
    self.templateEntities = {}

    tool.OnRelease(self)
end

return buildings_picker_tool
 