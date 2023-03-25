local item = require("lua/items/item.lua")

class 'teleport_explosion' ( item )

function teleport_explosion:__init()
    item.__init(self,self)
end

function teleport_explosion:OnInit()
    item.OnInit(self)

    self.machine = self:CreateStateMachine()
    self.machine:AddState( "marker", { from="*", execute= "OnMarkerExecute", exit="OnMarkerExit"} )
    
    self.marker = INVALID_ID
    self.foundPos = { false, {} }
    
    
    self:RegisterHandler( self.entity, "TeleportAppearEnter",  "OnTeleportAppearEnter" )
    self:RegisterHandler( self.entity, "TeleportAppearExit",  "OnTeleportAppearExit" )

    self:FillInitialParams()
end

function  teleport_explosion:OnLoad()
    item.OnLoad(self)
    self:FillInitialParams()
end

function teleport_explosion:FillInitialParams()
    
    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data
    
    self.maxDistance = database:GetFloatOrDefault("distance", -1.0 )
    
    self.explosionOnStart = database:GetIntOrDefault( "explosion_start", 0 ) == 1
    self.explosionOnEnd = database:GetIntOrDefault( "explosion_end", 0 ) == 1
    
    self.bp = database:GetStringOrDefault( "bp", "" )
    self.att = database:GetString( "att" )

    self.radiusBp = database:GetStringOrDefault( "radius_bp", "")
    self.radiusSize = database:GetFloatOrDefault("radius_size", 0)
    self.radiusLifeTime = database:GetFloatOrDefault("radius_lifetime", 0)
end

function teleport_explosion:SpawnExplosion()

    local team = EntityService:GetTeam( self.owner )

    local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, team )
    
    EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
    ItemService:SetItemCreator( spawned, self.bp )
    
    QueueEvent( "FadeEntityInRequest", spawned, 0.5 )

    if ( self.radiusBp ~= "" ) then

        local points = FindService:GetSpotsInRadius( self.owner, 0, self.radiusSize )

        for pos in Iter(points) do
            local trail = EntityService:SpawnEntity( self.radiusBp, pos, team )
            ItemService:SetItemCreator( trail, self.bp );
            EntityService:DissolveEntity( trail, self.radiusLifeTime, 1.0 )
        end
    end
end

function teleport_explosion:OnTeleportAppearEnter()
    self.data:SetInt("leaving", 1)
end

function teleport_explosion:OnTeleportAppearExit()
    self.data:SetInt("leaving", 0)
end

function teleport_explosion:OnOwnerTeleportAppearExit()
    
    self:SpawnExplosion()

    self:UnregisterHandler( self.owner, "TeleportAppearExit",  "OnOwnerTeleportAppearExit" )
end

function teleport_explosion:OnEquipped()
    self.machine:ChangeState("marker")
end

function teleport_explosion:OnUnequipped()
    local state  = self.machine:GetState(self.machine:GetCurrentState())
    if( state ~= nil ) then
        state:Exit()
    end
end

function teleport_explosion:OnActivate()

    if ( self.foundPos.first ) then
    
        if ( self.explosionOnStart ) then
            self:SpawnExplosion()
        end
    
        if ( self.explosionOnEnd ) then
            self:RegisterHandler( self.owner, "TeleportAppearExit",  "OnOwnerTeleportAppearExit" )
        end
        
        PlayerService:TeleportPlayer( self.owner, self.foundPos.second , 0.2, 0.1, 0.2 )
    end
end

function teleport_explosion:OnMarkerExecute( state )

    local pos = PlayerService:GetWeaponLookPoint( self.owner )
    
    self.foundPos = PlayerService:FindPositionForTeleport( self.owner, pos, self.maxDistance )
    
    if ( self.foundPos.first == false and self.marker ~= INVALID_ID ) then
    
        EntityService:RemoveEntity( self.marker )
        self.marker = INVALID_ID
        
    elseif ( self.foundPos.first and ( self.marker == INVALID_ID or EntityService:IsAlive( self.marker ) == false ) ) then
    
        self.marker = EntityService:SpawnEntity("effects/mech/teleport_marker", self.foundPos.second, EntityService:GetTeam(INVALID_ID) )
        
    elseif ( self.foundPos.first and self.marker ~= INVALID_ID ) then
    
        EntityService:SetPosition( self.marker, self.foundPos.second )
        EntityService:CreateOrSetLifetime( self.marker, 2.0 / 33.0, "normal" )
        EntityService:SetVisible( self.marker, PlayerService:IsInFighterMode( self.owner ) )
    end
end

function teleport_explosion:OnMarkerExit()
    EntityService:RemoveEntity( self.marker )
    self.marker = INVALID_ID
end

return teleport_explosion
