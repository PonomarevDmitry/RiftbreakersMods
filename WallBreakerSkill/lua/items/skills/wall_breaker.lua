local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'wall_breaker' ( item )

function wall_breaker:__init()
    item.__init(self,self)
end

function wall_breaker:CanActivate()

    local currentBiome = MissionService:GetCurrentBiomeName()
    if ( currentBiome == "caverns" ) then
        return true
    end

    return false
end

function wall_breaker:OnActivate()

    if ( self.owner == nil or self.owner == INVALID_ID ) then
        return
    end

    EffectService:SpawnEffect( self.owner, "effects/weapons_explosive/sonic_blast" )



    local databaseItem = EntityService:GetBlueprintDatabase( self.entity ) or self.data;



    local cleaner = EntityService:SpawnEntity( "items/skills/wall_breaker_cleaner", self.owner, "" )

    local database = EntityService:GetDatabase( cleaner )

    database:SetInt( "step_start", databaseItem:GetInt("step_start") )

    database:SetInt( "interval", databaseItem:GetInt("interval") )

    database:SetInt( "step_end", databaseItem:GetInt("step_end") )
end

return wall_breaker