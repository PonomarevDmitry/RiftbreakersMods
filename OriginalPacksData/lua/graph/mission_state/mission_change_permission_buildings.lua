require("lua/utils/string_utils.lua")
require("lua/utils/table_utils.lua")

class 'mission_change_permission_buildings' ( LuaGraphNode )

function mission_change_permission_buildings:__init()
	LuaGraphNode.__init(self,self)
end

function mission_change_permission_buildings:init()		
end

function mission_change_permission_buildings:Activated()							
	self.inputMask = self.data:GetString("building_bp")
	self.inputStatus = self.data:GetString("enabled")	
	LogService:Log( "BuildingBp  = " .. self.inputMask .. " " .. self.inputStatus )
	
	local buildings = Split( self.inputMask, "|" )

	if (self.inputStatus == "true" )then
		for building in Iter(buildings) do
			PlayerService:EnableBuilding( building )
		end
	else
		for building in Iter(buildings) do
			PlayerService:DisableBuilding( building )
		end
	end	
	self:SetFinished()	
end

return mission_change_permission_buildings