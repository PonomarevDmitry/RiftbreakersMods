require("lua/utils/string_utils.lua")

class 'interface_minimap_show_zone' ( LuaGraphNode )

function interface_minimap_show_zone:__init()
    LuaGraphNode.__init(self, self)
end

function interface_minimap_show_zone:init()
end

local function GetZonePosition( targetEntity, radius )
	local position = EntityService:GetPosition( targetEntity )
	if radius > 0.0 then
		position.x = position.x + RandFloat(-radius, radius)
		position.z = position.z + RandFloat(-radius, radius)
	end

	return position;
end

function interface_minimap_show_zone:Activated()
	local targetName = self.data:GetStringOrDefault("target_name", "");
	if self.data:GetIntOrDefault("target_name_is_global", 1) == 0 then
		targetName = self.parent:CreateGraphUniqueString(targetName)
	end

	if not Assert( not IsNullOrEmpty(targetName), "ERROR: `target_name` can NOT be empty!" ) then
		return self:SetFinished()
	end

	local markerName = self.data:GetStringOrDefault("marker_name", "");
	if self.data:GetIntOrDefault("marker_name_is_global", 1) == 0 then
		markerName = self.parent:CreateGraphUniqueString(markerName)
	end

	if not Assert( not IsNullOrEmpty(markerName), "ERROR: `marker_name` can NOT be empty!" ) then
		return self:SetFinished()
	end

	local targetEntity = FindService:FindEntityByName( targetName )
	if not Assert( targetEntity ~= INVALID_ID, "ERROR: could NOT find entity with name: `" .. targetName .. "`" ) then
		return self:SetFinished()
	end

	local randomizePosition = self.data:GetIntOrDefault("marker_randomize_position", 0)
	local markerRadius = self.data:GetFloatOrDefault("marker_radius", 10)

	local randomRadius = 0.0
	if randomizePosition == 1 then
		randomRadius = markerRadius
	end

	local color =
	{
		r = self.data:GetIntOrDefault("marker_color_r", 255) / 255,
		g = self.data:GetIntOrDefault("marker_color_g", 255) / 255,
		b = self.data:GetIntOrDefault("marker_color_b", 0) / 255,
		a = self.data:GetIntOrDefault("marker_color_a", 200) / 255
	}

	local position = GetZonePosition( targetEntity, randomRadius * 0.75 )
	GuiService:AddMinimapCircleMarker( position, markerName, markerRadius, color.r, color.g, color.b, 90 / 255 )

	self:SetFinished()
end

return interface_minimap_show_zone