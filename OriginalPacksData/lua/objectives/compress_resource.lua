class 'compress_resource' ( LuaObjectiveScript )

function compress_resource:__init()
	LuaObjectiveScript.__init(self,self)
end

function compress_resource:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )
	self:FindMaxResource()
    
    self.resourceName = self.data:GetStringOrDefault("resource_name", "")
end

function compress_resource:onUpdate()
	self:FindMaxResource()
    local blueprints =
    {
        "buildings/resources/liquid_compressor",
        "buildings/resources/liquid_compressor_lvl_2",
        "buildings/resources/liquid_compressor_lvl_3",
    }
    local entities = {}
    for  blueprint in Iter(blueprints) do
        ConcatUnique( entities, FindService:FindEntitiesByBlueprint( blueprint ) )
    end
    
    local progressCurrent = 0
    for ent in Iter( entities ) do
        if ( BuildingService:IsWorking( ent ) ) then
            local resourceConverterComponent = EntityService:GetComponent( ent, "ResourceConverterComponent")
            if ( resourceConverterComponent ~= nil ) then
                local lastOreProduced = resourceConverterComponent:GetField("last_ore_produced"):GetValue()
                local resource = lastOreProduced:gsub( "_compressed", "" )
                if ( resource == self.resourceName ) then
                    progressCurrent = progressCurrent + BuildingService:GetResourceProduction( ent, lastOreProduced)
                end
            end
        end
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

function compress_resource:FindMaxResource() 
	if ( self.maxProgress ~= nil ) then
		return self.maxProgress
	end

	if ( self.data:GetIntOrDefault("is_additional", 0) == 1 ) then
		local resourceName = self.data:GetString( "resource_name" )
		self.data:SetInt("progress_max", self.data:GetInt( "progress_max" ) + PlayerService:GetResourceAmount( resourceName ))
	end
	self.maxProgress = self.data:GetInt( "progress_max" )

end

return compress_resource
