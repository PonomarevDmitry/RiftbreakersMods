class 'interface_highlight_build_menu' ( LuaGraphNode )

function interface_highlight_build_menu:__init()
    LuaGraphNode.__init(self, self)
end

function interface_highlight_build_menu:init()		
end

function interface_highlight_build_menu:Activated()							
	self.item = self.data:GetString("item")
	self.status = self.data:GetString("status")	
	
	if self.status == "true" then
		GuiService:AddToHighlight( self.item )
	elseif self.status == "false" then
		GuiService:RemoveFromHighlight( self.item )
	end
	self:SetFinished()	
end

return interface_highlight_build_menu