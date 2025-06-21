local tool = require("lua/misc/tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")

class 'building_rotate_tool' ( tool )

function building_rotate_tool:__init()
    tool.__init(self,self)
end

function building_rotate_tool:OnInit()

    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_picker", self.entity)
    self.popupShown = false

    self.templateEntities = {}
end

function building_rotate_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function building_rotate_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function building_rotate_tool:AddedToSelection( entity )

    if ( IndexOf( self.templateEntities, entity ) == nil ) then

        self:SetEntitySelectedMaterial( entity, "hologram/current" )
    end
end

function building_rotate_tool:SetEntitySelectedMaterial( entity, material )

    EntityService:SetMaterial( entity, material, "selected" )

    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        if ( EntityService:HasComponent( child, "MeshComponent" ) and EntityService:HasComponent( child, "HealthComponent" ) ) then
            EntityService:SetMaterial( child, material, "selected" )
        end
    end
end

function building_rotate_tool:OnUpdate()

    for entity in Iter( self.templateEntities ) do

        self:SetEntitySelectedMaterial( entity, "hologram/active" )
    end
end

function building_rotate_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function building_rotate_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial(entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end


function building_rotate_tool:FilterSelectedEntities( selectedEntities ) 

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName( entity )

        local buildingDesc = BuildingService:GetBuildingDesc( blueprintName )
        if ( buildingDesc == nil ) then 
            goto continue 
        end

        local gridSize = BuildingService:GetBuildingGridSize( entity )
        if ( gridSize == nil ) then 
            goto continue 
        end

        if ( gridSize.x ~= gridSize.z ) then 
            goto continue 
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function building_rotate_tool:OnActivateSelectorRequest()
    
    if ( #self.selectedEntities == 0 ) then
        return
    end

    if ( self.templateEntities ~= nil) then
        for entity in Iter( self.templateEntities ) do
            self:RemovedFromSelection( entity )
        end
    end
    
    self.templateEntities = {}

    for entity in Iter( self.selectedEntities ) do
        Insert( self.templateEntities, entity )
    end

    self:OnUpdate()
end

function building_rotate_tool:OnRelease()
    
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

function building_rotate_tool:OnRotateSelectorRequest(evt)

    local degree = evt:GetDegree()

    -- Inverting rotation
    if ( mod_invert_rotation ~= nil and mod_invert_rotation == 1 ) then
        degree = -degree
    end

    for entity in Iter(self.templateEntities) do

        EntityService:Rotate( entity, 0.0, 1.0, 0.0, degree )

        local transform = EntityService:GetWorldTransform( entity )
        EntityService:SetOrientation( entity, transform.orientation )

        BuildingService:CheckAndFixBuildingConnection( entity )
    end

    self:OnUpdate()
end

return building_rotate_tool