require("lua/utils/reflection.lua")

class 'wall_breaker_cleaner' ( LuaEntityObject )

function wall_breaker_cleaner:__init()
    LuaEntityObject.__init(self,self)
end

function wall_breaker_cleaner:init()

    self.step = self.data:GetInt("step_start")
    self.interval = self.data:GetInt("interval")
    self.stepEnd = self.data:GetInt("step_end")

    self.team = EntityService:GetTeam( self.entity )

    self:InitFsmStateMachine()

    self.fsm:ChangeState( "clean_path" )
end

function wall_breaker_cleaner:OnLoad()

    self:InitFsmStateMachine()
end

function wall_breaker_cleaner:InitFsmStateMachine()

    if ( self.fsm ~= nil ) then
        return
    end

    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "clean_path", { execute="OnExecuteCleanPath", interval = 0.5 } )
end

function wall_breaker_cleaner:OnExecuteCleanPath( state )

    local position = EntityService:GetPosition( self.entity )

    local blueprintName = "items/consumables/wall_breaker_culler_" .. string.format( "%02d", self.step )

    if ( ResourceManager:ResourceExists( "EntityBlueprint", blueprintName ) ) then

        local culler = EntityService:SpawnEntity( blueprintName, position, self.team )

        EntityService:CreateLifeTime( culler, 0.1, "normal" )
    end

    self.step = self.step + self.interval

    if ( self.step > self.stepEnd ) then
        return state:Exit()
    end
end

function wall_breaker_cleaner:OnRelease()

    self:StopWorking()
end

function wall_breaker_cleaner:StopWorking()

    if ( self.fsm ~= nil ) then

        self.fsm:Deactivate()
    end
end

return wall_breaker_cleaner