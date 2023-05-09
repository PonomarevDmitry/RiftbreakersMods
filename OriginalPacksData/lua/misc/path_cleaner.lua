class 'path_cleaner' ( LuaEntityObject )

function path_cleaner:__init()
	LuaEntityObject.__init(self,self)
end

function path_cleaner:init()
	
	local fromEntity = tonumber( self.data:GetString( "from_entity" ) )
	local toEntity = tonumber( self.data:GetString( "to_entity" ) )

	self.path = UnitService:GetGroundPath( fromEntity, toEntity )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "clean_path", { execute="OnExecuteCleanPath", exit="OnExitCleanPath", interval=0.1 } )
	self.fsm:ChangeState( "clean_path" )

	self.team = EntityService:GetTeam(self.entity)
	self.step = 1
end

function GetBlueprintForOffset( offset )
	if offset < 5 then
		return "misc/path_cleanear_grid_culler_small"
	end

		return "misc/path_cleanear_grid_culler_medium"
end

function path_cleaner:OnExecuteCleanPath( state )

	local points_coint = #self.path

	local offset_start = self.step;
	local offset_end = points_coint - self.step + 1;

	local origin1 = self.path[ offset_start ]
	local origin2 = self.path[ offset_end ]

	local blueprint = GetBlueprintForOffset(offset_start)
	if origin1 then
		local culler1 = EntityService:SpawnEntity(blueprint, origin1, self.team)
		EntityService:CreateLifeTime(culler1, 0.05, "normal")
	end

	if origin2 then
		local culler2 = EntityService:SpawnEntity(blueprint, origin2,self.team )
		EntityService:CreateLifeTime(culler2, 0.05, "normal")
	end

	if points_coint / 2 < self.step then
		return state:Exit()
	end

	self.step = self.step + 1
end

function path_cleaner:OnExitCleanPath( state )
	EntityService:RemoveEntity( self.entity )
end

return path_cleaner
