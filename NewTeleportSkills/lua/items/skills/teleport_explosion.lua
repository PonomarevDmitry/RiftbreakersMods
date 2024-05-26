local teleport = require("lua/items/skills/teleport.lua")

class 'teleport_explosion' ( teleport )

function teleport_explosion:__init()
    teleport.__init(self,self)
end

function teleport_explosion:OnInit()
    if ( teleport.OnInit ) then
        teleport.OnInit(self)
    end

    self:FillInitialParams()
end

function teleport_explosion:OnLoad()
    if ( teleport.OnLoad ) then
        teleport.OnLoad(self)
    end

    self:FillInitialParams()
end

function teleport_explosion:FillInitialParams()

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.maxDistance = database:GetFloatOrDefault( "distance", -1.0 )

    self.explosionOnStart = database:GetIntOrDefault( "explosion_start", 0 ) == 1
    self.explosionOnEnd = database:GetIntOrDefault( "explosion_end", 0 ) == 1

    self.bp = database:GetStringOrDefault( "bp", "" )
    self.att = database:GetStringOrDefault( "att", "" )

    self.radiusBp = database:GetStringOrDefault( "radius_bp", "")
    self.radiusSize = database:GetFloatOrDefault( "radius_size", 0 )
    self.radiusLifeTime = database:GetFloatOrDefault( "radius_lifetime", 0 )
end

function teleport_explosion:OnActivate()

    self:UnregisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )

    if ( self.foundPos.first ) then
    
        if ( self.explosionOnStart ) then
            self:SpawnExplosion()
        end

        if ( self.explosionOnEnd ) then
            self:RegisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )
        end
    end

    if ( teleport.OnActivate ) then
        teleport.OnActivate(self)
    end
end

function teleport_explosion:OnOwnerRiftTeleportEndEvent()

    self:UnregisterHandler( self.owner, "RiftTeleportEndEvent", "OnOwnerRiftTeleportEndEvent" )

    self:SpawnExplosion()
end

function teleport_explosion:SpawnExplosion()

    local team = EntityService:GetTeam( self.owner )

    local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, team )

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
    ItemService:SetItemCreator( spawned, EntityService:GetBlueprintName(self.entity) )
    EntityService:PropagateEntityOwner( spawned, self.owner )

    QueueEvent( "FadeEntityInRequest", spawned, 0.5 )

    if ( self.radiusBp ~= "" ) then

        local points = FindService:GetSpotsInRadius( self.owner, 0, self.radiusSize )

        for pos in Iter(points) do
            local trail = EntityService:SpawnEntity( self.radiusBp, pos, team )
            ItemService:SetItemCreator( trail, EntityService:GetBlueprintName(self.entity) );
            EntityService:PropagateEntityOwner( trail, self.owner )
            EntityService:DissolveEntity( trail, self.radiusLifeTime, 1.0 )
        end
    end
end

return teleport_explosion