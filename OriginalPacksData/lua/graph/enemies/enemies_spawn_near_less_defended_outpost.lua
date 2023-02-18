require("lua/utils/find_utils.lua")

class 'enemies_spawn_near_less_defended_outpost' ( LuaGraphNode )

function enemies_spawn_near_less_defended_outpost:__init()
    LuaGraphNode.__init(self, self)
end

function enemies_spawn_near_less_defended_outpost:init()

	local enemyBlueprint = self.data:GetString( "enemy_blueprint" )
	local seek			 = self.data:GetString( "seek" )
	local avoid		     = self.data:GetString( "avoid" )
	local count			 = self.data:GetInt( "count" )
	local distance		 = self.data:GetInt( "distance" )
	local unitState		 = self.data:GetString( "unit_state" )
	
	UnitService:SpawnUnitsNearLessDefendedOutpost( enemyBlueprint, count, seek, avoid, distance, unitState )

	self:SetFinished()

end




return enemies_spawn_near_less_defended_outpost