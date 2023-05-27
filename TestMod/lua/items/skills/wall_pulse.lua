local item = require("lua/items/item.lua")
require("lua/utils/reflection.lua")

class 'wall_pulse' ( item )

function wall_pulse:__init()
    item.__init(self,self)
end

function wall_pulse:OnInit()

    self:InitFsmStateMachine()
end

function wall_pulse:OnLoad()

    self:InitFsmStateMachine()
end

function wall_pulse:InitFsmStateMachine()

    if ( self.fsm ~= nil ) then
        return
    end

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "clean_path", { execute="OnExecuteCleanPath", interval = 0.1 } )
end

function wall_pulse:CanActivate()

    local currentBiome = MissionService:GetCurrentBiomeName()
    if ( currentBiome == "caverns" ) then
        return true
    end

    return false
end

function wall_pulse:OnActivate()

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

function wall_pulse:OnExecuteCleanPath( state )

    local blueprintName = "items/consumables/wall_pulse_" .. string.format( "%02d", self.step )

    LogService:Log("OnExecuteCleanPath " .. blueprintName)

    if ( ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        local culler = EntityService:SpawnEntity( blueprintName, self.playerPosition, self.team )

        EntityService:CreateLifeTime( culler, 0.05, "normal" )
    end

    self.step = self.step + self.interval

    if ( self.step > self.stepEnd ) then
        return state:Exit()
    end
end

return wall_pulse