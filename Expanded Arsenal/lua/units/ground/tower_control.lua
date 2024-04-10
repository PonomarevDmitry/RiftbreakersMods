require("lua/utils/table_utils.lua")
require("lua/utils/string_utils.lua")

class 'tower_control' ( LuaEntityObject )

function tower_control:__init()
	LuaEntityObject.__init(self, self)
end

function tower_control:init()
	self.selected = {}
	self:hacking()
end

function tower_control:hacking()
	local hacking_radius = self.data:GetFloatOrDefault("hacking_radius", 3)
	local hacking_duration = self.data:GetFloatOrDefault("hacking_duration", 5)
	
	local predicate = {
		signature = "TeamComponent",
		type="tower",
		filter = function(entity)
			return EntityService:IsInTeamRelation(self.entity, entity, "hostility")
		end
	};

	local HackedTowers = FindService:FindEntitiesByPredicateInRadius( self.entity, hacking_radius, predicate );
	
	for i = 1, #HackedTowers do
		if( IndexOf( self.selected, HackedTowers[i] ) == nil and BuildingService:IsBuildingFinished( HackedTowers[i] ) and HealthService:IsAlive(HackedTowers[i]) ) then
			local isWorking = BuildingService:IsWorking( HackedTowers[i] )
			if isWorking == true then
				EntityService:SetTeam(HackedTowers[i], "wave_enemy");
				EntityService:ChangeType(HackedTowers[i], "ground_unit");
				Insert( self.selected, HackedTowers[i] );
			end
		end
	end
	
	local ent = EntityService:CreateEntity("effects/enemies_generic/tower_control_timer")
	EntityService:CreateLifeTime( ent, hacking_duration, "normal")
	local data = EntityService:GetDatabase(ent)
	for t = 1, #self.selected do
		data:SetInt( "ent" .. tostring(t), self.selected[t])
	end
end

return tower_control