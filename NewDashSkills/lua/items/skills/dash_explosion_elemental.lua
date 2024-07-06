local firetrail_dash = require("lua/items/skills/firetrail_dash.lua")

class 'dash_explosion' ( firetrail_dash )

function dash_explosion:__init()
    dash.__init(self,self)
end

function dash_explosion:OnInit()
    if ( firetrail_dash.OnInit ) then
        firetrail_dash.OnInit(self)
    end

    self:FillInitialParams()
end

function dash_explosion:OnLoad()
    if ( firetrail_dash.OnLoad ) then
        firetrail_dash.OnLoad(self)
    end

    self:FillInitialParams()
end

function dash_explosion:FillInitialParams()

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.bp = database:GetStringOrDefault( "bp", "" )
    self.att = database:GetStringOrDefault( "att", "" )

    self.radiusBp = database:GetStringOrDefault( "radius_bp", "")
    self.radiusSize = database:GetFloatOrDefault( "radius_size", 0 )
    self.radiusLifeTime = database:GetFloatOrDefault( "radius_lifetime", 0 )
end

function dash_explosion:OnActivate()

    self:SpawnExplosion()

    if ( firetrail_dash.OnActivate ) then
        firetrail_dash.OnActivate(self)
    end
end

function dash_explosion:SpawnExplosion()

    local team = EntityService:GetTeam( self.owner )

    local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, team )

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
    ItemService:SetItemCreator( spawned, EntityService:GetBlueprintName(self.entity) )
    EntityService:PropagateEntityOwner( spawned, self.owner )

    --QueueEvent( "FadeEntityInRequest", spawned, 0.5 )
    EntityService:FadeEntity( spawned, DD_FADE_IN, 0.5 )

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

return dash_explosion
