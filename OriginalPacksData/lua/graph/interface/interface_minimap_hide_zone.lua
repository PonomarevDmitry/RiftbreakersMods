require("lua/utils/string_utils.lua")

class 'interface_minimap_hide_zone' ( LuaGraphNode )

function interface_minimap_hide_zone:__init()
    LuaGraphNode.__init(self, self)
end

function interface_minimap_hide_zone:init()
end

function interface_minimap_hide_zone:Activated()
	local markerName = self.data:GetStringOrDefault("marker_name", "");
	if self.data:GetIntOrDefault("name_is_global", 1) == 0 then
		markerName = self.parent:CreateGraphUniqueString(markerName)
	end

	if not Assert( not IsNullOrEmpty( markerName ), "ERROR: `marker_name` can NOT be empty!" ) then
		return self:SetFinished()
	end

	GuiService:RemoveMinimapMarker(markerName)

    self:SetFinished()
end

return interface_minimap_hide_zone