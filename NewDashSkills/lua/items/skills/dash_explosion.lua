local dash = require("lua/items/skills/dash.lua")

class 'dash_explosion' ( dash )

function dash_explosion:__init()
    dash.__init(self,self)
end

function dash_explosion:OnInit()
    if ( dash.OnInit ) then
        dash.OnInit(self)
    end

    self:FillInitialParams()
end

function dash_explosion:OnLoad()
    if ( dash.OnLoad ) then
        dash.OnLoad(self)
    end

    self:FillInitialParams()
end

function dash_explosion:FillInitialParams()

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.bp = database:GetStringOrDefault( "bp", "" )
    self.att = database:GetStringOrDefault( "att", "" )
end

function dash_explosion:OnActivate()

    self:SpawnExplosion()

    if ( dash.OnActivate ) then
        dash.OnActivate(self)
    end
end

function dash_explosion:SpawnExplosion()

    local team = EntityService:GetTeam( self.owner )

    local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, team )

    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
    ItemService:SetItemCreator( spawned, EntityService:GetBlueprintName(self.entity) )

    QueueEvent( "FadeEntityInRequest", spawned, 0.5 )
end

return dash_explosion