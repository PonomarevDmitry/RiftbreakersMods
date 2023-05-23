local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'personal_rift_portal' ( item )

function personal_rift_portal:__init()
    item.__init(self,self)
end

function personal_rift_portal:OnEquipped()
    self.duration = 0.0
end

function personal_rift_portal:OnActivate()

    self.duration = self.duration or 0.0

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.teleportBefore = database:GetFloat("teleport_before")
    self.spawnAfter = database:GetFloat("spawn_after")

    if ( self.teleportBefore <= self.duration and self.duration <= self.spawnAfter ) then

        if ( self.timer == nil ) then

            QueueEvent( "AddMaxSpeedModifierRequest", self.owner, "personal_rift_portal_penalty", 0 )

            local timeBeforeSpawn = (self.spawnAfter - self.teleportBefore)

            self.timer = BuildingService:CreateGuiTimer( self.owner, timeBeforeSpawn )
        else

            local passTime = (self.duration - self.teleportBefore)

            BuildingService:SetGuiTimer( self.timer, passTime )
        end
    elseif ( self.spawnAfter < self.duration ) then

        if ( self.timer ~= nil ) then

            self:DestroyTimer()

            self:SpawnPortal( "misc/personal_rift" )
        end
    end

    self.duration = self.duration + 1.0 / 30.0
end

function personal_rift_portal:DestroyTimer()

    if ( self.timer ~= nil ) then

        EntityService:RemoveEntity( self.timer )
        self.timer = nil

        QueueEvent( "RemoveMaxSpeedModifierRequest", self.owner, "personal_rift_portal_penalty" )
    end
end

function personal_rift_portal:OnDeactivate()

    self:DestroyTimer()

    if ( self.duration < self.teleportBefore ) then

        local entities = FindService:FindEntitiesByBlueprint( "misc/personal_rift" )

        if ( #entities > 0 ) then

            local portal = entities[#entities]

            local portalPosition = EntityService:GetPosition( portal )

            self:SpawnPortal( "misc/rift" )

            PlayerService:TeleportPlayer( self.owner, portalPosition , 0.2, 0.1, 0.2 )
        end
    end

    self.duration = 0.0

    return true
end

function personal_rift_portal:SpawnPortal(blueprintName)

    local entities = FindService:FindEntitiesByBlueprint( blueprintName )

    for i=1,#entities do
        QueueEvent( "DissolveEntityRequest", entities[i], 0.5, 0 )
    end

    local team = EntityService:GetTeam( self.entity )

    local playerPosition = EntityService:GetPosition( self.owner )

    local newPortal = EntityService:SpawnEntity( blueprintName, playerPosition, team )
end

return personal_rift_portal