require( "lua/utils/building_utils.lua" )

class 'build_stabilizators_nearby' ( LuaObjectiveScript )

function build_stabilizators_nearby:__init()
	LuaObjectiveScript.__init(self,self)
end

function build_stabilizators_nearby:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:ChangeState( "update" )
		
	
	self.entityName = self.data:GetString( "entity_name" )
	self.entity = FindService:FindEntityByName( self.entityName )
	
	self.stabilizerCount  = 4
	if (EntityService:IsAlive( self.entity) ) then
		local db = EntityService:GetDatabase( self.entity )
		self.stabilizatorsRadius = db:GetFloatOrDefault("stabilizators_radius", 100 )
		self.alienFactor		= db:GetIntOrDefault("alien_stablizators_factor", 1 )	
		self.stabilizerCount	= db:GetIntOrDefault("stabilizators_count", 4 )
	end
	self.data:SetInt( "progress_max", self.stabilizerCount )

end

function build_stabilizators_nearby:onUpdate()
	if ( EntityService:IsAlive( self.entity ) == false ) then
	    ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
  		self.data:SetInt( "progress_current", 0 )
		self.entity = FindService:FindEntityByName( self.entityName )
		
		if (EntityService:IsAlive( self.entity) ) then
			local db = EntityService:GetDatabase( self.entity )
			self.stabilizatorsRadius = db:GetFloatOrDefault("stabilizators_radius", 100 )
			self.alienFactor		= db:GetIntOrDefault("alien_stablizators_factor", 1 )	
			self.stabilizerCount	= db:GetIntOrDefault("stabilizators_count", 4 )
			self.data:SetInt( "progress_max", self.stabilizerCount )
		end
		return
	end
	
	self.stabilzatorsCount = GetWorkingStabilizatorsCount( self.entity, self.stabilizatorsRadius, self.alienFactor)
	
	if ( self.stabilzatorsCount >= self.stabilizerCount  ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	elseif( self.stabilzatorsCount < self.stabilizerCount  ) then
	   ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
    end
	
	self.data:SetInt( "progress_current", self.stabilzatorsCount )
end


return build_stabilizators_nearby
