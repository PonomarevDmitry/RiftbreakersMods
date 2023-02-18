class 'interface_show_controls' ( LuaGraphNode )

function interface_show_controls:__init()
    LuaGraphNode.__init(self, self)
end

function interface_show_controls:init()
end

function interface_show_controls:Activated()
	GuiService:ShowHudControls()
    self:SetFinished()
end

return interface_show_controls