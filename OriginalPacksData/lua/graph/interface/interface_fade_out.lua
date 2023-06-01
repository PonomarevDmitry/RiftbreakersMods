class 'interface_fade_out' ( LuaGraphNode )

function interface_fade_out:__init()
    LuaGraphNode.__init(self, self)
end

function interface_fade_out:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "fade", { from="*", enter="OnFade", exit="OnFadeExit" } )
end

function interface_fade_out:Activated()
	self.fadeOut = self.data:GetFloat("fade_out")
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
end


function interface_fade_out:OnFade( state )
	state:SetDurationLimit( self.fadeOut )
end

function interface_fade_out:OnFadeExit( state )
	self:SetFinished()
end

return interface_fade_out