local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")
require("lua/utils/table_utils.lua")
require("lua/utils/numeric_utils.lua")

class 'rift_jump_to_hq' ( item )

function rift_jump_to_hq:__init()
    item.__init(self,self)
end

function rift_jump_to_hq:OnEquipped()
end

function rift_jump_to_hq:OnActivate()

    local findResult = FindService:FindEntityByName( "headquarters" )
    if ( findResult ~= nil and findResult ~= INVALID_ID ) then

        self:JumpToHQ(findResult)
        return
    end

    findResult = FindService:FindEntityByName( "outpost" )
    if ( findResult ~= nil and findResult ~= INVALID_ID ) then

        self:JumpToHQ(findResult)
        return
    end
end

function rift_jump_to_hq:JumpToHQ(entity)

    local childrenList = EntityService:GetChildren( entity, false )

    for childEntity in Iter( childrenList ) do

        local blueprintName = EntityService:GetBlueprintName( childEntity )

        if ( blueprintName == "buildings/main/headquarters/portal" ) then

            local portalPosition = EntityService:GetPosition( childEntity )

            self:SpawnPortal( "misc/rift" )

            PlayerService:TeleportPlayer( self.owner, portalPosition , 0.2, 0.1, 0.2 )

            return
        end
    end
end

function rift_jump_to_hq:SpawnPortal(blueprintName)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.5, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return rift_jump_to_hq