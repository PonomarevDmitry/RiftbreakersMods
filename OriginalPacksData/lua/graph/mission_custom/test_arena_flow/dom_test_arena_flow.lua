class 'dom_test_arena_flow' ( LuaGraphNode )

function dom_test_arena_flow:__init()
	LuaGraphNode.__init(self,self)
end

function dom_test_arena_flow:init()    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { enter="OnEnterWait", exit= "OnExitWait" } )
	self.RandomSpawnPointNumber = 0
	self.RandomWaveNumber = 0
	self.wavePool = {
		"logic/wave/wave_level_1.logic",
		"logic/wave/wave_level_2.logic",
		"logic/wave/wave_level_3.logic"
	}	
end

function dom_test_arena_flow:Activated()		
	self.fsm:ChangeState("wait")
end

function dom_test_arena_flow:RandomizeSpawnPoint()
	--self.SpawnPointName = self.data:GetString("spawn_" .. tostring(RandInt(1,3)))	
	self.SpawnPointPool = FindService:FindEntitiesByBlueprint( "logic/spawn_enemy" )	
	if #self.SpawnPointPool > 1 then
		repeat
			self.TempRandomNumber = RandInt(1,#self.SpawnPointPool)
		until self.TempRandomNumber ~= self.RandomSpawnPointNumber
		self.RandomSpawnPointNumber = self.TempRandomNumber
	else
		self.RandomSpawnPointNumber = 1
	end
	
	local SpawnPointId = self.SpawnPointPool[self.RandomSpawnPointNumber]
	self.SpawnPointName = EntityService:GetName( SpawnPointId )	
	self.data:SetString("spawn_point", self.SpawnPointName )
end

function dom_test_arena_flow:RandomizeWave()
	--self.SpawnPointName = self.data:GetString("spawn_" .. tostring(RandInt(1,3)))	
	
	if #self.wavePool > 1 then
		repeat
			self.TempRandomNumber = RandInt(1,#self.wavePool)
		until self.TempRandomNumber ~= self.RandomWaveNumber
		self.RandomWaveNumber = self.TempRandomNumber
	else
		self.RandomWaveNumber = 1
	end	
	self.WaveName = self.wavePool[self.RandomWaveNumber]
end

function dom_test_arena_flow:OnEnterWait( state )
	LogService:Log("DomPrototype OnEnterWait")    
    state:SetDurationLimit( 1 )	
	if ( MissionService:IsGraphActive("fala") == false ) then		
		self:RandomizeSpawnPoint()
		self:RandomizeWave()
		LogService:Log("Number of SpawnPoints on the map = " .. #self.SpawnPointPool)
		LogService:Log("SpawnPoint Name = " .. self.data:GetString("spawn_point") )
		MissionService:ActivateMissionFlow( "fala", self.WaveName, "default", self.data )				
	end	
	
	
end

function dom_test_arena_flow:OnExitWait( state )
	LogService:Log("DomPrototype OnExitWait")
    self.fsm:ChangeState("wait")
	--self:SetFinished()
end


return dom_test_arena_flow