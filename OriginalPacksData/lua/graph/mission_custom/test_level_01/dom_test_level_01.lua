class 'dom_test_level_01' ( LuaGraphNode )

function dom_test_level_01:__init()
	LuaGraphNode.__init(self,self)
end

function dom_test_level_01:init()    
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { enter="OnEnterWait", exit= "OnExitWait" } )
	self.RandomNumber = 0
	
end

function dom_test_level_01:Activated()		
	self.fsm:ChangeState("wait")
end

function dom_test_level_01:RandomizeSpawnPoint()
	--self.SpawnPointName = self.data:GetString("spawn_" .. tostring(RandInt(1,3)))	
	self.SpawnPointPool = FindService:FindEntitiesByBlueprint( "logic/spawn_enemy" )	
	if #self.SpawnPointPool > 1 then
		repeat
			self.TempRandomNumber = RandInt(1,#self.SpawnPointPool)
		until self.TempRandomNumber ~= self.RandomNumber
		self.RandomNumber = self.TempRandomNumber
	else
		self.RandomNumber = 1
	end
	
	local SpawnPointId = self.SpawnPointPool[self.RandomNumber]
	self.SpawnPointName = EntityService:GetName( SpawnPointId )	
	self.data:SetString("spawn_point", self.SpawnPointName )
end

function dom_test_level_01:OnEnterWait( state )
	LogService:Log("DomPrototype OnEnterWait")
	self:RandomizeSpawnPoint()
	LogService:Log("Number of SpawnPoints on the map = " .. #self.SpawnPointPool)
	LogService:Log("SpawnPoint Name = " .. self.data:GetString("spawn_point") )
    --local duration = self.data:GetFloat("duration")
    state:SetDurationLimit( 90 )	
	if ( MissionService:IsGraphActive("fala") == false ) and ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) and ( #FindService:FindEntitiesByBlueprint( "buildings/defense/basic_tower" ) > 9 ) then		
		MissionService:ActivateMissionFlow( "fala", "logic/missions/test/level_01/wave_level_3.logic", "default", self.data )			
	elseif ( MissionService:IsGraphActive("fala") == false ) and ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) and ( #FindService:FindEntitiesByBlueprint( "buildings/defense/basic_tower" ) > 4 ) then
		MissionService:ActivateMissionFlow( "fala", "logic/missions/test/level_01/wave_level_2.logic", "default", self.data )		
	elseif ( MissionService:IsGraphActive("fala") == false ) and ( #FindService:FindEntitiesByBlueprint( "buildings/main/headquarters" ) > 0 ) then		
		MissionService:ActivateMissionFlow( "fala", "logic/missions/test/level_01/wave_level_1.logic", "default", self.data )
	end	
	
	
end

function dom_test_level_01:OnExitWait( state )
	LogService:Log("DomPrototype OnExitWait")
    self.fsm:ChangeState("wait")
	--self:SetFinished()
end

return dom_test_level_01