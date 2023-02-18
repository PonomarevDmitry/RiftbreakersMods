class 'interface_cutscene_start' ( LuaGraphNode )

function interface_cutscene_start:__init()
    LuaGraphNode.__init(self, self)
end

function interface_cutscene_start:init()
	
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "fade_in", { from="*", enter="OnFadeIn", exit="OnFadeInExit" } )
	self.sm:AddState( "fade", { from="*", enter="OnFade", exit="OnFadeExit" } )
	self.sm:AddState( "fade_out", { from="*", enter="OnFadeOut",exit="OnFadeOutExit" } )
	
end

function interface_cutscene_start:Activated()

	self.sm:ChangeState("fade_in")
	
	self.cutscene_strip = self.data:GetInt("strips") == 1
	self.hudMask = self.data:GetString( "hud_mask" )
	self.fadeIn = self.data:GetFloat("fade_in")
	self.fadeOut = self.data:GetFloat("fade_out")
	self.fadeDuration = self.data:GetFloat("fade_duration")

end

function interface_cutscene_start:OnFadeIn( state )
	GuiService:FadeOut(self.fadeOut)
	state:SetDurationLimit( self.fadeOut )
	LogService:Log("OnFadeIn")
end

function interface_cutscene_start:OnFadeInExit( state )
	LogService:Log("OnFadeInExit")
	self.sm:ChangeState("fade")
end

function interface_cutscene_start:OnFade( state )
	LogService:Log("OnFade")
	state:SetDurationLimit( self.fadeDuration )
	if ( self.cutscene_strip == true ) then
		GuiService:ShowCutsceneStrips()
	end
	GuiService:OperateHudByMask( self.hudMask, false )	
end

function interface_cutscene_start:OnFadeExit( state )
	LogService:Log("OnFadeExit")
	self.sm:ChangeState("fade_out")
end

function interface_cutscene_start:OnFadeOut( state )
	LogService:Log("OnFadeOut")
	state:SetDurationLimit( self.fadeIn )
	GuiService:FadeIn( self.fadeIn )
end

function interface_cutscene_start:OnFadeOutExit( state )
	LogService:Log("OnFadeOutExit")
	self:SetFinished()
end

return interface_cutscene_start