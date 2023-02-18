require("lua/utils/find_utils.lua")

class 'mission_ambient_creatures_spawn' ( LuaGraphNode )

function mission_ambient_creatures_spawn:__init()
    LuaGraphNode.__init(self, self)
end

function mission_ambient_creatures_spawn:init()

	local ambientCreaturesEnableSpawn = self.data:GetString( "ambient_creatures_enable_spawn" )

	if ( ambientCreaturesEnableSpawn == 'true' ) then
		UnitService:EnableAmbientUnitsSpawn()
	else
		UnitService:DisableAmbientUnitsSpawn()
	end
	

	self:SetFinished()

end




return mission_ambient_creatures_spawn