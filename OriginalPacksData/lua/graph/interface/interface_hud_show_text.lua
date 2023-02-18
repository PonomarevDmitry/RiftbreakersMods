class 'interface_hud_show_text' ( LuaGraphNode )

function interface_hud_show_text:__init()
    LuaGraphNode.__init(self, self)
end

function interface_hud_show_text:init()
end

function interface_hud_show_text:Activated()
	local id 		= self.data:GetString("id")
	local content   = self.data:GetString("content")
	
	GuiService:ShowHudText( id, content )
    self:SetFinished()
end


return interface_hud_show_text