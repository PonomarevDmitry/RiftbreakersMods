class 'interface_hud_visible' ( LuaGraphNode )

function interface_hud_visible:__init()
    LuaGraphNode.__init(self, self)
end

function interface_hud_visible:init()
end

function interface_hud_visible:Activated()

	local visible = self.data:GetInt("visible") == 1
	local hudMask = self.data:GetString( "hud_mask" )
	
	GuiService:OperateHudByMask( hudMask, visible )	
    self:SetFinished()
end

return interface_hud_visible