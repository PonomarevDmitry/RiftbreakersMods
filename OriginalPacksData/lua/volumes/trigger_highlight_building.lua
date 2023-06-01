class 'trigger_highlight_building' ( LuaEntityObject )
require("lua/utils/string_utils.lua")
require("lua/utils/reflection.lua")

function trigger_highlight_building:__init()
	LuaEntityObject.__init(self, self)
end

function trigger_highlight_building:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )
	local highlightsVec = self.data:GetString("highlights")
	self.highlights = Split(highlightsVec, ",")

	self.remove_from_highlight = false
end

function trigger_highlight_building:OnEnteredTriggerEvent( evt )
	self.remove_from_highlight = true
	for name in Iter(self.highlights) do
		GuiService:AddToHighlight( name )
	end
end

function trigger_highlight_building:OnLeftTriggerEvent( evt )
	self.remove_from_highlight = false
	for name in Iter(self.highlights) do
		GuiService:RemoveFromHighlight( name )
	end
end

function trigger_highlight_building:OnRelease( )
	if not self.remove_from_highlight then
		return
	end
	
	for name in Iter(self.highlights) do
		GuiService:RemoveFromHighlight( name )
	end
end

return trigger_highlight_building