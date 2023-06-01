class 'interface_fade_in' ( LuaGraphNode )

function interface_fade_in:__init()
    LuaGraphNode.__init(self, self)
end

function interface_fade_in:init()
	self.sm = self:CreateStateMachine()
	self.sm:AddState( "fade", { from="*", enter="OnFade", exit="OnFadeExit" } )
end

function interface_fade_in:Activated()
	self.fadeIn = self.data:GetFloat("fade_in")
	GuiService:FadeIn( self.fadeIn )
	self.sm:ChangeState("fade")
end


function interface_fade_in:OnFade( state )
	state:SetDurationLimit( self.fadeIn )
end

function interface_fade_in:OnFadeExit( state )
	self:SetFinished()
end

return interface_fade_in