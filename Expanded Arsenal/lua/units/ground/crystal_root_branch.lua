require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'crystal_root_branch' ( base_unit )

function crystal_root_branch:__init()
	base_unit.__init(self, self)
end

function crystal_root_branch:init()
	self:RegisterHandler( self.entity, "DestroyRequest",  "OnDestroyRequest" )
	self.enemy_spawn = self.data:GetStringOrDefault("enemy_spawn", "units/ground/morirot")
	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 4
end

function crystal_root_branch:OnDestroyRequest( evt )
	EntityService:RequestDestroyPattern( self.entity, "default" )
	local origin = EntityService:GetPosition(self.entity)
	local enemy_spawn = EntityService:SpawnEntity(self.enemy_spawn, origin.x, origin.y, origin.z, "" )
	EntityService:SetTeam( enemy_spawn, "wave_enemy" )
	UnitService:SetInitialState( enemy_spawn, UNIT_AGGRESSIVE);
end

return crystal_root_branch
