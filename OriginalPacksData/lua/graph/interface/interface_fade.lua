class 'interface_fade' ( LuaGraphNode )

function interface_fade:__init()
    LuaGraphNode.__init(self, self)
end

function interface_fade:init()
	
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "fade", { from="*", enter="OnFade", exit="OnFadeExit" } )
	self.sm:AddState( "fade_out", { from="*", enter="OnFadeOut",exit="OnFadeOutExit" } )
	
end

function interface_fade:Activated()

	self.fadeIn = self.data:GetFloat("fade_in")
	self.fadeOut = self.data:GetFloat("fade_out")
	self.fadeDuration = self.data:GetFloat("duration")
	self.color = {
		x = self.data:GetFloatOrDefault("color_r", 0) / 255,
		y = self.data:GetFloatOrDefault("color_g", 0) / 255,
		z = self.data:GetFloatOrDefault("color_b", 0) / 255
	}
		
	if ( GuiService.FadeOutToColor ) then
		GuiService:FadeOutToColor( self.fadeOut,self.color )	
	else
		GuiService:FadeOut( self.fadeOut )	
	end
	self.sm:ChangeState("fade")

	--ogService:Log("fade: " .. tostring( self.fadeIn ) .. ":" .. tostring( self.fadeOut ) .. ":" .. tostring( self.fadeDuration ) )
    --self:SetFinished()
end


function interface_fade:OnFade( state )

	LogService:Log("OnFade")
	state:SetDurationLimit( self.fadeOut + self.fadeDuration )
end

function interface_fade:OnFadeExit( state )
	LogService:Log("OnFadeExit")
	self.sm:ChangeState("fade_out")
end

function interface_fade:OnFadeOut( state )
	LogService:Log("OnFadeOut")
	state:SetDurationLimit( self.fadeOut)
	GuiService:FadeIn(self.fadeIn )
end

function interface_fade:OnFadeOutExit( state )
	LogService:Log("OnFadeOutExit")
	self:SetFinished()
end

return interface_fade