class 'interface_dialogue_show' ( LuaGraphNode )

function interface_dialogue_show:__init()
    LuaGraphNode.__init(self, self)
end

function interface_dialogue_show:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "show_dialog", { from="*", enter="OnEnterShowDialog", exit="OnExitShowDialog" } ) 
end

function interface_dialogue_show:Activated()
    self.has_handler = false
    self.fsm:ChangeState( "show_dialog" )
end

function interface_dialogue_show:Deactivated()
    if self.has_handler then
        self.has_handler = false
        self:UnregisterHandler( event_sink, "DialogEndEvent", "OnDialogEnd" )
    end
end

function interface_dialogue_show:OnEnterShowDialog( state )
    self.gui_id = self.data:GetString("gui_id")
    self.sound_name = self.data:GetString("sound_name")
    self.localization_id = self.data:GetString("localization_id")
    self.extended_duration = self.data:GetFloat("extended_duration")
    self.manual_hide = self.data:GetString("manual_hide") == "true" 
    self.interrupt = self.data:GetString("interrupt") == "true" 
	self.global = self.data:GetStringOrDefault("global", "false") == "true" 
    self.priority = self.data:GetFloat("priority") 
    self.timeout = self.data:GetFloat("timeout") 
    
    self.localization_id = string.gsub( self.sound_name, "voice_over/", "DIALOG/")
        
    self.soundDuration = 0;
    self.isSlowdownAffected = true;
    if self.sound_name ~= nil or self.sound_name ~= "" then 
        self.soundDuration = SoundService:GetSoundDuration( self.sound_name )
        self.isSlowdownAffected = SoundService:IsRuntimeFreqRatioControlEnabled( self.sound_name );
    end

    self.time = 0
    self.time = self.soundDuration + self.extended_duration
    GuiService:ShowDialog( self.gui_id, self.localization_id, self.sound_name, self.priority, self.time, self.manual_hide, self.isSlowdownAffected, self.interrupt, self.timeout, self.global)
    --LogService:Log( tostring( self.entity ) )
    
    self.has_handler = true
	self:RegisterHandler( event_sink , "DialogEndEvent", "OnDialogEnd")	
    --state:SetDurationLimit( self.time ) 
    --self.current_state = state
end

function interface_dialogue_show:OnDialogEnd( event )
    if event:GetDialogId() == self.localization_id then
        LogService:Log("OnDialogEnd = " .. tostring(self.localization_id) )
		self.fsm:GetState("show_dialog"):Exit()
    end
end

function interface_dialogue_show:OnExitShowDialog( state )
    LogService:Log("OnExitShowDialog = " .. tostring(self.localization_id) )
    self:SetFinished()
end

return interface_dialogue_show