local building = require("lua/buildings/building.lua")
require("lua/utils/table_utils.lua")

class 'ea_vent_extractor' ( building )

function ea_vent_extractor:__init()
	building.__init(self)
	self.veins = {}
end

function ea_vent_extractor:OnCubeFlyStart()
	self:ClearResourceVent()
end

function ea_vent_extractor:ClearResourceVent()
	local vent = self.data:GetStringOrDefault("vent_type","")
	self.veins = BuildingService:GetResourceVeins( self.entity, vent)
	for vent in Iter(self.veins ) do
		EffectService:DestroyEffectsByGroup( vent, "steam")
		EffectService:DestroyEffectsByGroup( vent, "vent_terrain_marker")
	end
end

function ea_vent_extractor:OnBuildingEnd()
	if ( #self.veins == 0 ) then
		self:ClearResourceVent()
	end
end

function ea_vent_extractor:OnRemove()
	for vent in Iter(self.veins ) do
		EffectService:AttachEffects( vent, "steam")
		EffectService:AttachEffects( vent, "vent_terrain_marker")
	end
end

return ea_vent_extractor
