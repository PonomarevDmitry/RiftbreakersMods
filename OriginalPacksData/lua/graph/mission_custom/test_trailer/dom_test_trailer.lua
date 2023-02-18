class 'dom_test_trailer' ( LuaGraphNode )

function dom_test_trailer:__init()
	LuaGraphNode.__init(self,self)
end

function dom_test_trailer:init()    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { enter="OnEnterWait", exit= "OnExitWait" } )
	self.RandomNumber = 0
	
end

function dom_test_trailer:Activated()		
	self.fsm:ChangeState("wait")
end

function dom_test_trailer:RandomizeSpawnPoint()
	--self.SpawnPointName = self.data:GetString("spawn_" .. tostring(RandInt(1,3)))	
	--self.SpawnPointPool = FindService:FindEntitiesByBlueprint( "logic/spawn_enemy" )	
	
	self.SpawnPointPool = {
		"logic/spawn_enemy_border_west_1",
		"logic/spawn_enemy_border_west_2",
		"logic/spawn_enemy_border_south_1",
		"logic/spawn_enemy_border_south_2",
		"logic/spawn_enemy_border_south_3",
		"logic/spawn_enemy_border_north_1",
		"logic/spawn_enemy_border_north_2",
		"logic/spawn_enemy_border_east_1",
		"logic/spawn_enemy_border_east_2"	
	}
	
	if #self.SpawnPointPool > 1 then
		repeat
			self.TempRandomNumber = RandInt(1,#self.SpawnPointPool)
		until self.TempRandomNumber ~= self.RandomNumber
		self.RandomNumber = self.TempRandomNumber
	else
		self.RandomNumber = 1
	end
	
	--local SpawnPointId = self.SpawnPointPool[self.RandomNumber]
	--self.SpawnPointName = EntityService:GetName( SpawnPointId )	
	--self.data:SetString("spawn_point", self.SpawnPointName )
	self.SpawnPointName = self.SpawnPointPool[self.RandomNumber]	
	self.data:SetString("spawn_point", self.SpawnPointName )
end

function dom_test_trailer:OnEnterWait( state )
	LogService:Log("DomPrototype OnEnterWait")
	self:RandomizeSpawnPoint()
	LogService:Log("Number of SpawnPoints on the map = " .. #self.SpawnPointPool)
	LogService:Log("SpawnPoint Name = " .. self.data:GetString("spawn_point") )
    --local duration = self.data:GetFloat("duration")
    state:SetDurationLimit( 300 )	
	if ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) and ( #FindService:FindEntitiesByBlueprint( "buildings/defense/basic_tower" ) > 9 ) then		
		MissionService:ActivateMissionFlow( "", "logic/missions/test/trailer/wave_level_3.logic", "default", self.data )
		--state:SetDurationLimit( 15 )
	elseif ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) and ( #FindService:FindEntitiesByBlueprint( "buildings/defense/basic_tower" ) > 5 ) then
		MissionService:ActivateMissionFlow( "", "logic/missions/test/trailer/wave_level_2.logic", "default", self.data )
		--state:SetDurationLimit( 30 )
	elseif ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) then		
		MissionService:ActivateMissionFlow( "", "logic/missions/test/trailer/wave_level_1.logic", "default", self.data )
	end	
	
	
end

function dom_test_trailer:OnExitWait( state )
	LogService:Log("DomPrototype OnExitWait")
    self.fsm:ChangeState("wait")
	--self:SetFinished()
end

return dom_test_trailer