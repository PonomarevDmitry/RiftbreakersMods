class 'gather_resource' ( LuaObjectiveScript )

function gather_resource:__init()
	LuaObjectiveScript.__init(self,self)
end

function gather_resource:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )
	self:FindMaxResource()
end

function gather_resource:onUpdate()
	self:FindMaxResource()
	local resourceName = self.data:GetString( "resource_name" )
	local progressCurrent = PlayerService:GetResourceAmount( resourceName )

    if ( progressCurrent >= self.maxProgress ) then
	   if ( self.data:GetIntOrDefault( "finish_objective", 1) == 1) then
		   ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   	   self.fsm:ChangeState( "idle" )
		else
	       ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   end
	   progressCurrent = self.maxProgress
	else
		ObjectiveService:SetObjectiveStatusByObjectiveId( self.objective_id, OBJECTIVE_IN_PROGRESS )
    end

	self.data:SetInt( "progress_current", progressCurrent )

end

function gather_resource:FindMaxResource() 
	if ( self.maxProgress ~= nil ) then
		return self.maxProgress
	end

	if ( self.data:GetIntOrDefault("is_additional", 0) == 1 ) then
		local resourceName = self.data:GetString( "resource_name" )
		self.data:SetInt("progress_max", self.data:GetInt( "progress_max" ) + PlayerService:GetResourceAmount( resourceName ))
	end
	self.maxProgress = self.data:GetInt( "progress_max" )

end

return gather_resource
