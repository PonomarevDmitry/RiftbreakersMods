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
	local resourceNames = self.data:GetString( "resource_name" )
	local resourceName = Split( resourceNames, "|" )
	local progressCurrent = 0
	local leadingPlayer = PlayerService:GetLeadingPlayer()

	for resource in Iter(resourceName) do
		progressCurrent = progressCurrent + PlayerService:GetResourceAmount(leadingPlayer, resource )
	end

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
		local resourceNames = self.data:GetString( "resource_name" )
		local resourceName = Split( resourceNames, "|" )
		local progressCurrent = 0
		local leadingPlayer = PlayerService:GetLeadingPlayer()

		for resource in Iter(resourceName) do
			progressCurrent = progressCurrent + PlayerService:GetResourceAmount(leadingPlayer, resource )
		end
		self.data:SetInt("progress_max", self.data:GetInt( "progress_max" ) + progressCurrent)
	end
	self.maxProgress = self.data:GetInt( "progress_max" )

end

return gather_resource
