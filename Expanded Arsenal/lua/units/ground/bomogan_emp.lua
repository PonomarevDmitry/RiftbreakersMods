require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'bomogan_emp' ( LuaEntityObject )

function bomogan_emp:__init()
	LuaEntityObject.__init(self, self)
end

function bomogan_emp:init()
	self.selected = {}
	self:emp()
end

function bomogan_emp:emp()
	local EMPradius = self.data:GetFloatOrDefault("EMP_radius", 6)
	local modAffectedBuildings = FindService:FindEntitiesByTypeInRadius( self.entity, "building", EMPradius )
	
	for i = 1, #modAffectedBuildings do
		if( IndexOf( self.selected, modAffectedBuildings[i] ) == nil and BuildingService:IsBuildingFinished( modAffectedBuildings[i] ) )
		then
			local isWorking = BuildingService:IsWorking( modAffectedBuildings[i] )
			local bldgName = BuildingService:GetBuildingName(modAffectedBuildings[i])
			if (string.find(bldgName, "wall") ~= 1)
			then
				if (string.find(bldgName, "energy") ~= 1)
				then
					if isWorking == true
					then
						BuildingService:DisableBuilding( modAffectedBuildings[i] )	
						EntityService:SpawnEntity( "effects/messages_and_markers/building_disabled", modAffectedBuildings[i], "" )
						EffectService:AttachEffects(modAffectedBuildings[i], "building_disable")
						Insert( self.selected, modAffectedBuildings[i] )
					end
				end	
			end
		end
	end
	local ent = EntityService:CreateEntity("effects/enemies_generic/bomotimer")
	local EMPduration = self.data:GetFloatOrDefault("EMP_duration", 10)
	EntityService:CreateLifeTime( ent, EMPduration, "normal")
	local data = EntityService:GetDatabase(ent)
	for t = 1, #self.selected do
		data:SetInt( "ent" .. tostring(t), self.selected[t])
	end
end

return bomogan_emp