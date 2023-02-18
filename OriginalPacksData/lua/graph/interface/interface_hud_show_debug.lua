class 'interface_hud_show_debug' ( LuaGraphNode )

function interface_hud_show_debug:__init()
    LuaGraphNode.__init(self, self)
end

function interface_hud_show_debug:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "show_text", { from="*", enter="OnEnterShowText", execute="OnExecuteShowText", exit= "OnExitShowText" } )
end

function interface_hud_show_debug:Activated()
    self.fsm:ChangeState( "show_text" )
end

function interface_hud_show_debug:OnEnterShowText( state )
    self.duration = self.data:GetFloat( "duration" )
    self.text = self.data:GetString( "text" )
    if self.duration ~= 0 then
        state:SetDurationLimit( self.duration )
    else 
        state:Exit()
    end

    LogService:Log( self.text )
end

function interface_hud_show_debug:OnExecuteShowText( state )
    LogService:DebugText( 600, 350, self.text, "debug_white_size_38" )
end

function interface_hud_show_debug:OnExitShowText( state )
    self:SetFinished()
end

return interface_hud_show_debug