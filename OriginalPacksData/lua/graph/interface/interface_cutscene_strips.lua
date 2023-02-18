class 'interface_cutscene_strips' ( LuaGraphNode )

function interface_cutscene_strips:__init()
    LuaGraphNode.__init(self, self)
end

function interface_cutscene_strips:init()
end

function interface_cutscene_strips:Activated()

	local visible = self.data:GetInt("visible") == 1
	
	if ( visible == true ) then
		GuiService:ShowCutsceneStrips()
	else
		GuiService:HideCutsceneStrips()
	end
	
	
    self:SetFinished()
end

return interface_cutscene_strips