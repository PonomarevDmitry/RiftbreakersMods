require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'unit_control' ( LuaEntityObject )

function unit_control:__init()
	LuaEntityObject.__init(self, self)
end

function unit_control:init()
	self.selected = {}
	self:mind_control()
end

function unit_control:mind_control()
	local control_radius = self.data:GetFloatOrDefault("control_radius", 3)
	local control_duration = self.data:GetFloatOrDefault("control_duration", 10)
	
	local predicate = {
		signature = "TeamComponent",
		type="ground_unit",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt( 0 ), entity, "hostility")
		end
	};

	local ControlledUnits = FindService:FindEntitiesByPredicateInRadius( self.entity, control_radius, predicate );
	
	for i = 1, #ControlledUnits do
		if( IndexOf( self.selected, ControlledUnits[i] ) == nil and HealthService:IsAlive( ControlledUnits[i] ) )then
			EntityService:SetTeam(ControlledUnits[i], "player")
			Insert( self.selected, ControlledUnits[i] )
		end
	end
	
	local ent = EntityService:CreateEntity("effects/enemies_generic/unit_control_timer")
	EntityService:CreateLifeTime( ent, control_duration, "normal")
	local data = EntityService:GetDatabase(ent)
	for t = 1, #self.selected do
		data:SetInt( "ent" .. tostring(t), self.selected[t])
	end
end

return unit_control