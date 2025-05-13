class 'gather_energy_in_building' ( LuaObjectiveScript )

function gather_energy_in_building:__init()
	LuaObjectiveScript.__init(self,self)
end

function gather_energy_in_building:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:ChangeState( "update" )
		
	self.progressMax = self.data:GetInt( "progress_max" )
	self.entityName = self.data:GetString( "entity_name" )
	self.entity = FindService:FindEntityByName( self.entityName )
end

function gather_energy_in_building:onUpdate()
	if ( EntityService:IsAlive( self.entity ) == false ) then
	    ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
  		self.data:SetInt( "progress_current", 0 )
		self.entity = FindService:FindEntityByName( self.entityName )
		return
	end
	
	self.energyProgress = PlayerService:GetResourceAmount( "energy" )
	
	if ( self.energyProgress >= self.progressMax  ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	elseif( self.energyProgress < self.progressMax  ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
    end
	
	self.data:SetInt( "progress_current", self.energyProgress )
end


return gather_energy_in_building
