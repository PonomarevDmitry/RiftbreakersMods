require("lua/utils/string_utils.lua")

class 'interface_minimap_show_zone_objective' ( LuaGraphNode )

function interface_minimap_show_zone_objective:__init()
    LuaGraphNode.__init(self, self)
end

function interface_minimap_show_zone_objective:init()
end

local function GetZonePosition( targetEntity, radius )
	local position = EntityService:GetPosition( targetEntity )
	if radius > 0.0 then
		position.x = position.x + RandFloat(-radius, radius)
		position.z = position.z + RandFloat(-radius, radius)
	end

	return position;
end

function interface_minimap_show_zone_objective:Activated()
	local targetName = self.data:GetStringOrDefault("target_name", "");
	if not Assert( not IsNullOrEmpty(targetName), "ERROR: `target_name` can NOT be empty!" ) then
		return self:SetFinished()
	end

	local markerName = self.data:GetStringOrDefault("marker_name", "");
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

	local objectiveName =  self.data:GetString( "unique_name_id" )
	if self.data:GetIntOrDefault("is_objective_local", 1) == 1 then
		objectiveName = self.parent:CreateGraphUniqueString( objectiveName )
	end

    local objectiveId = ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( objectiveName )
	if not Assert( objectiveId ~= INVALID_OBJECTIVE_ID, "ERROR: could NOT find objective with name: `" .. objectiveName .. "`" ) then
		return self:SetFinished()
	end

    local color = ObjectiveService:GetObjectiveColor(objectiveId)
	local iconMaterial = ObjectiveService:GetObjectiveMinimapIcon(objectiveId)
	local position = GetZonePosition( targetEntity, randomRadius * 0.75 )
	GuiService:AddMinimapCircleMarker( position, markerName, markerRadius, color.x, color.y, color.z, color.w )
	GuiService:SetMinimapMarkerIconMaterial(markerName,iconMaterial)
	self:SetFinished()
end

return interface_minimap_show_zone_objective