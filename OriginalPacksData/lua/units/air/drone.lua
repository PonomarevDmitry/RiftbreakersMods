require("lua/units/units_utils.lua")
class 'drone' ( LuaEntityObject )

function drone:__init()
	LuaEntityObject.__init(self, self)
end

function drone:init()
	SetupUnitScale( self.entity, self.data )
	self:RegisterHandler( self.entity, "EnableDroneRequest",  "OnEnableDroneRequest" )
	self:RegisterHandler( self.entity, "DisableDroneRequest",  "OnDisableDroneRequest" )
	self:RegisterHandler( self.entity, "DestroyRequest", "OnDestroyRequest" )
end

function drone:OnEnableDroneRequest( evt )
	local storage = self.data:GetFloatOrDefault("storage", 1);
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", storage )

	if self.FillInitialParams then
		self:FillInitialParams();
	end
end

function drone:OnDisableDroneRequest( evt )
	EntityService:SetGraphicsUniform( self.entity, "cGlowFactor", 0 )
end

function drone:OnDestroyRequest( req )
	EntityService:ClearResourceDroneTarget(self.entity) 
end

return drone
