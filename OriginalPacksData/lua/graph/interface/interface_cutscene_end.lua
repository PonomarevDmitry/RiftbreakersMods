class 'interface_cutscene_end' ( LuaGraphNode )

function interface_cutscene_end:__init()
    LuaGraphNode.__init(self, self)
end

function interface_cutscene_end:init()	
	
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "fade_in", { from="*", enter="OnFadeIn", exit="OnFadeInExit" } )
	self.sm:AddState( "fade", { from="*", enter="OnFade", exit="OnFadeExit" } )
	self.sm:AddState( "fade_out", { from="*", enter="OnFadeOut",exit="OnFadeOutExit" } )
		
end

function interface_cutscene_end:Activated()

	self.sm:ChangeState("fade_in")
	
	self.hudMask = self.data:GetString( "hud_mask" )
	self.fadeIn = self.data:GetFloat("fade_in")
	self.fadeOut = self.data:GetFloat("fade_out")
	self.fadeDuration = self.data:GetFloat("fade_duration")

end

function interface_cutscene_end:OnFadeIn( state )
	GuiService:FadeOut(self.fadeOut)
	state:SetDurationLimit( self.fadeOut )
end

function interface_cutscene_end:OnFadeInExit( state )
	self.sm:ChangeState("fade")
end

function interface_cutscene_end:CameraFollowPlayer()
 	local players = PlayerService:GetConnectedPlayers()
	for player in Iter( players ) do
		local camera = CameraService:GetPlayerCamera( player )
		local playerEnt = PlayerService:GetPlayerControlledEnt( player )
		CameraService:SetFollowTarget( camera, playerEnt )
	end
end

function interface_cutscene_end:OnFade( state )
	state:SetDurationLimit( self.fadeDuration )
	GuiService:HideCutsceneStrips()
	GuiService:OperateHudByMask( self.hudMask, true )	
	self:CameraFollowPlayer()
end

function interface_cutscene_end:OnFadeExit( state )
	self.sm:ChangeState("fade_out")
end

function interface_cutscene_end:OnFadeOut( state )
	state:SetDurationLimit( self.fadeIn )
	GuiService:FadeIn(self.fadeIn)
end

function interface_cutscene_end:OnFadeOutExit( state )
	self:SetFinished()
end

return interface_cutscene_end