local portal_base_tool = require("lua/misc/portal_base_tool.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")
require("lua/utils/building_utils.lua")
require("lua/utils/find_utils.lua")

class 'portal_chain_tool' ( portal_base_tool )

function portal_chain_tool:__init()
    portal_base_tool.__init(self,self)
end

function portal_chain_tool:OnInit()

    EntityService:SetVisible( self.entity , false )
    EntityService:SetScale( self.entity, 2, 1, 2 )

    local transform = EntityService:GetWorldTransform( self.entity )

    local position = {}
    position.x = 0
    position.y = 0
    position.z = 0
    
    self.ghostPortal = self:SpawnGhostPortalEntity(position, transform.orientation)
end

function portal_chain_tool:OnUpdate()

    if ( self.activated and self.buildStartTransform ~= nil ) then

        self:BuildPortals()
    end
end

function portal_chain_tool:BuildPortals()

    local currentPosition = EntityService:GetWorldTransform( self.entity )

    local spots = BuildingService:FindSpotsByDistance( self.buildStartTransform, currentPosition, self.radius, self.portalBlueprintName )

    for spot in Iter( spots ) do

        self:BuildEntity(self.ghostPortal, spot, true)

        self.buildStartTransform = spot
    end

    self.activated = true
end

function portal_chain_tool:OnActivateSelectorRequest()

    self.buildStartTransform = nil
    self.activated = false

    local entities = FindService:FindEntitiesByBlueprint( self.portalBlueprintName )

    ConcatUnique( entities, FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) )

    ConcatUnique( entities, FindService:FindEntitiesByBlueprint( "buildings/main/outpost" ) )

    if ( #entities == 0 ) then
        return
    end

    local target = FindClosestEntity( self.entity, entities )

    if ( target == nil or target == INVALID_ID ) then
        return
    end

    self.buildStartTransform = EntityService:GetWorldTransform( target )

    self:BuildPortals()

    self.activated = true
end

function portal_chain_tool:OnDeactivateSelectorRequest()

    self.buildStartTransform = nil
    self.activated = false
end

function portal_chain_tool:OnRotateSelectorRequest(evt)
end

function portal_chain_tool:OnRelease()

    EntityService:RemoveEntity(self.ghostPortal)

    if ( portal_base_tool.OnRelease ) then
        portal_base_tool.OnRelease(self)
    end
end

return portal_chain_tool