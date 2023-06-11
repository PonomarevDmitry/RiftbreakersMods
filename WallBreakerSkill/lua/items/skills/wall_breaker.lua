local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'wall_breaker' ( item )

function wall_breaker:__init()
    item.__init(self,self)
end

function wall_breaker:OnInit()

    if ( item.OnInit ) then
        item.OnInit(self)
    end

    self:InitFsmStateMachine()
end

function wall_breaker:OnLoad()

    if ( item.OnLoad ) then
        item.OnLoad(self)
    end

    self:InitFsmStateMachine()
end

function wall_breaker:InitFsmStateMachine()

    if ( self.fsm ~= nil ) then
        return
    end

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "clean_path", { execute="OnExecuteCleanPath", interval = 0.5 } )
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

    local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;

    self.step = database:GetInt("step_start")
    self.interval = database:GetInt("interval")
    self.stepEnd = database:GetInt("step_end")

    self.team = EntityService:GetTeam( self.entity )
    self.playerPosition = EntityService:GetPosition( self.owner )

    EffectService:SpawnEffect( self.owner, "effects/weapons_explosive/sonic_blast" )

    self.fsm:ChangeState( "clean_path" )
end

function wall_breaker:OnExecuteCleanPath( state )

    local blueprintName = "items/consumables/wall_breaker_" .. string.format( "%02d", self.step )

    if ( ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        local culler = EntityService:SpawnEntity( blueprintName, self.playerPosition, self.team )

        EntityService:CreateLifeTime( culler, 0.05, "normal" )
    end

    self.step = self.step + self.interval

    if ( self.step > self.stepEnd ) then
        return state:Exit()
    end
end

function wall_breaker:OnUnequipped()

    self:StopWorking()
end

function wall_breaker:StopWorking()

    if ( self.fsm ~= nil ) then

        self.fsm:Deactivate()
    end
end

function wall_breaker:OnRelease()

    self:StopWorking()

    if ( item.OnRelease ) then
        item.OnRelease(self)
    end
end

return wall_breaker