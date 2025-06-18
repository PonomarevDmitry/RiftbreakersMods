local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'artificial_spawner_activate_tool' ( tool )

function artificial_spawner_activate_tool:__init()
    tool.__init(self,self)
end

function artificial_spawner_activate_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_artificial_spawner_activate_tool", self.entity)

    self.player = PlayerService:GetPlayerControlledEnt(self.playerId)

    self.activatedEntities = {}
end

function artificial_spawner_activate_tool:OnPreInit()
    self.initialScale = { x=8, y=1, z=8 }
end

function artificial_spawner_activate_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function artificial_spawner_activate_tool:FilterSelectedEntities( selectedEntities )

    local entities = {}

    for entity in Iter( selectedEntities ) do

        local blueprintName = EntityService:GetBlueprintName(entity)

        if ( blueprintName ~= "buildings/main/artificial_spawner" ) then
            goto continue
        end

        if ( IndexOf( self.activatedEntities, entity ) ~= nil ) then
            goto continue
        end

        Insert(entities, entity)

        ::continue::
    end

    return entities
end

function artificial_spawner_activate_tool:AddedToSelection( entity )
    local skinned = EntityService:IsSkinned(entity)
    if ( skinned ) then
        EntityService:SetMaterial( entity, "selector/hologram_current_skinned", "selected" )
    else
        EntityService:SetMaterial( entity, "selector/hologram_current", "selected" )
    end
end

function artificial_spawner_activate_tool:RemovedFromSelection( entity )
    EntityService:RemoveMaterial( entity, "selected" )
    local children = EntityService:GetChildren( entity, true )
    for child in Iter( children ) do
        EntityService:RemoveMaterial( child, "selected" )
    end
end

function artificial_spawner_activate_tool:OnRotate()
end

function artificial_spawner_activate_tool:OnActivateSelectorRequest()

    self.activatedEntities = {}

    self.activated = true
    for entity in Iter( self.selectedEntities ) do
        self:OnActivateEntity( entity )
    end
end

function artificial_spawner_activate_tool:OnActivateEntity( entity )

    self.activatedEntities = self.activatedEntities or {}

    if ( IndexOf( self.activatedEntities, entity ) ~= nil ) then
        return
    end

    QueueEvent( "InteractWithEntityRequest", entity, self.player )

    Insert(self.activatedEntities, entity)
end

return artificial_spawner_activate_tool
