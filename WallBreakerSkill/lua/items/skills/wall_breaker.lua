local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'wall_breaker' ( item )

function wall_breaker:__init()
    item.__init(self,self)
end

function wall_breaker:OnEquipped()
    self.duration = 0.0
end

function wall_breaker:CanActivate()

    local currentBiome = MissionService:GetCurrentBiomeName()
    if ( currentBiome == "caverns" ) then
        return true
    end

    return false
end

function wall_breaker:OnActivate()

    self.duration = self.duration or 0.0



    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data

    self.activateAfter = database:GetFloat("activate_after")

    if ( 0 <= self.duration and self.duration <= self.activateAfter ) then

        if ( self.timer == nil ) then

            self.penaltySpeedOwner = self.owner

            QueueEvent( "AddMaxSpeedModifierRequest", self.penaltySpeedOwner, "wall_breaker_penalty", 0 )

            self.timer = BuildingService:CreateGuiTimer( self.owner, self.activateAfter )
        else

            BuildingService:SetGuiTimer( self.timer, self.duration )
        end

    elseif ( self.activateAfter < self.duration ) then

        if ( self.timer ~= nil ) then

            self:DestroyTimer()

            if ( self.owner ~= nil and self.owner ~= INVALID_ID ) then

                EffectService:SpawnEffect( self.owner, "effects/weapons_explosive/sonic_blast" )



                local cleaner = EntityService:SpawnEntity( "items/skills/wall_breaker_cleaner", self.owner, "" )

                local databaseCleaner = EntityService:GetOrCreateDatabase( cleaner )

                databaseCleaner:SetInt( "step_start", database:GetInt("step_start") )

                databaseCleaner:SetInt( "interval", database:GetInt("interval") )

                databaseCleaner:SetInt( "step_end", database:GetInt("step_end") )
            end
        end
    end

    self.duration = self.duration + 1.0 / 30.0
end

function wall_breaker:DestroyTimer()

    if ( self.timer ~= nil ) then

        EntityService:RemoveEntity( self.timer )
        self.timer = nil

        if ( self.penaltySpeedOwner ~= nil ) then

            QueueEvent( "RemoveMaxSpeedModifierRequest", self.penaltySpeedOwner, "wall_breaker_penalty" )
        end
    end
end

function wall_breaker:OnDeactivate()

    self:DestroyTimer()

    self.duration = 0.0

    return true
end

function wall_breaker:OnUnequipped()

    self:DestroyTimer()

    if ( item.OnUnequipped ) then
        item.OnUnequipped( self )
    end
end

return wall_breaker