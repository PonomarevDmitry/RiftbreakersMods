class 'interface_hud_hide_text' ( LuaGraphNode )

function interface_hud_hide_text:__init()
    LuaGraphNode.__init(self, self)
end

function interface_hud_hide_text:init()
end

function interface_hud_hide_text:Activated()
	local id 		= self.data:GetString("id")
	GuiService:HideHudText( id )
    self:SetFinished()
end


return interface_hud_hide_text