require("lua/utils/find_utils.lua")

class 'objective_spawn_blueprint' ( LuaGraphNodeSelector )

function objective_spawn_blueprint:__init()
	LuaGraphNodeSelector.__init(self, self)
end

function objective_spawn_blueprint:init()
end

function objective_spawn_blueprint:Activated()
	Assert( self.data:HasString("blueprint") and self.data:HasString("target") and self.data:HasString("marker"), "No blueprint, target or marker for objective in database!" )
	self.blueprint = self.data:GetString( "blueprint");
	self.targetName = self.data:GetString( "target" );
	self.markerName = self.data:GetStringOrDefault( "marker", "");
	self.team = self.data:GetStringOrDefault( "team", "enemy");

	local objectiveSpawn = MissionService:SpawnMissionObjective(self.blueprint)
	if objectiveSpawn ~= INVALID_ID then
		if ( self.markerName ~= "" ) then
			local markerEntity = EntityService:SpawnEntity( "effects/messages_and_markers/objective_marker_red", objectiveSpawn, "no_team" )	
			EntityService:SetName( markerEntity, self.markerName )
		end

		if self.team ~= "" then
			EntityService:SetTeam( objectiveSpawn, self.team )
		end

		if self.targetName ~= "" then
			EntityService:SetName( objectiveSpawn, self.targetName )
		end

		EntityService:SetGroup( objectiveSpawn, "objective" )

		self:SetFinished("true")
	else
		self:SetFinished("false")
	end
end

return objective_spawn_blueprint