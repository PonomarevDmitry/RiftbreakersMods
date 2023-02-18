class 'interface_dialogue_hide' ( LuaGraphNode )

function interface_dialogue_hide:__init()
    LuaGraphNode.__init(self, self)
end

function interface_dialogue_hide:init()
end

function interface_dialogue_hide:Activated()
    self.localization_id = self.data:GetString("localization_id")
    GuiService:HideDialog( self.localization_id )
    self:SetFinished()
end

return interface_dialogue_hide