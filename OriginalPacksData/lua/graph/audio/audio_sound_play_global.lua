class 'sound_play_global' ( LuaGraphNode )

function sound_play_global:__init()
    LuaGraphNode.__init(self, self)
end

function sound_play_global:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit="OnExitWait" } )
end

function sound_play_global:Activated()
    self.fsm:ChangeState( "wait" )
    
    self.soundName = self.data:GetString("sound_name")
    self.soundDuration = SoundService:GetSoundDuration( self.soundName )
    SoundService:Play( self.soundName )
end

function sound_play_global:OnEnterWait( state )
    state:SetDurationLimit( self.soundDuration )
end

function sound_play_global:OnExitWait( state )
    self:SetFinished()
end

return sound_play_global