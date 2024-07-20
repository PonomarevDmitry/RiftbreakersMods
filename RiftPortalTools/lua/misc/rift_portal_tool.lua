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

    local position = EntityService:GetPosition( self.entity )

    if ( FindService:IsGridMarkedWithLayer(position, "TeleportBlockerLayerComponent") ) then

        SoundService:Play( "gui/cannot_use_item" )
        return
    end

    if ( FindService:IsGridMarkedWithLayer(position, "WorldBlockerLayerComponent") ) then

        SoundService:Play( "gui/cannot_use_item" )
        return
    end

    self:DissolveRirtPortalEntities(blueprintName)

    local team = EntityService:GetTeam( self.entity )

    local newPortal = EntityService:SpawnEntity( blueprintName, position, team )

    local playerReferenceComponentRef = reflection_helper(EntityService:CreateComponent(newPortal, "PlayerReferenceComponent"))
    playerReferenceComponentRef.player_id = self.playerId
    playerReferenceComponentRef.reference_type.internal_enum = 3
end

function rift_portal_tool:DissolveRirtPortalEntities(blueprintName)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for entity in Iter( entities ) do

        local playerReferenceComponent = EntityService:GetComponent( entity, "PlayerReferenceComponent" )
        if (playerReferenceComponent) then

            local playerReferenceComponentRef = reflection_helper(playerReferenceComponent)

            if (playerReferenceComponentRef and playerReferenceComponentRef.player_id == self.playerId) then

                QueueEvent( "DissolveEntityRequest", entity, 0.2, 0 )
            end
        end
    end
end

return rift_portal_tool
