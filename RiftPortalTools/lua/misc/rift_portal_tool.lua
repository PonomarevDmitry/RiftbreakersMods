local tool = require("lua/misc/tool.lua")
require("lua/utils/table_utils.lua")

class 'rift_portal_tool' ( tool )

function rift_portal_tool:__init()
    tool.__init(self,self)
end

function rift_portal_tool:OnInit()
    self.childEntity = EntityService:SpawnAndAttachEntity("misc/marker_selector_rift_portal_tool", self.entity)
end

function rift_portal_tool:SpawnCornerBlueprint()
    if ( self.corners == nil ) then
        self.corners = EntityService:SpawnAndAttachEntity("misc/marker_selector_corner_tool", self.entity )
    end
end

function rift_portal_tool:OnPreInit()
    self.initialScale = { x=1, y=1, z=1 }
end

function rift_portal_tool:GetScaleFromDatabase()
    return { x=1, y=1, z=1 }
end

function rift_portal_tool:FindEntitiesToSelect( selectorComponent )

    return {}
end

function rift_portal_tool:AddedToSelection( entity )
end

function rift_portal_tool:RemovedFromSelection( entity )
end

function rift_portal_tool:OnRotate()
end

function rift_portal_tool:OnRotateSelectorRequest(evt)
end

function rift_portal_tool:OnActivateSelectorRequest()
    
    self:SpawnPortal( "misc/rift" )
end

function rift_portal_tool:SpawnPortal(blueprintName)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.2, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local position = EntityService:GetPosition( self.entity )

    local newPortal = EntityService:SpawnEntity( blueprintName, position, team )
end

return rift_portal_tool
