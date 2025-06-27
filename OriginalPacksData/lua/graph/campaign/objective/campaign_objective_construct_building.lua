class 'campaign_objective_construct_building' ( LuaObjectiveScript )

function campaign_objective_construct_building:__init()
	LuaObjectiveScript.__init(self,self)
end

function campaign_objective_construct_building:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )

    self.progressMax = self.data:GetInt( "progress_max" )
	self.type = self.data:GetStringOrDefault( "type", "" )
	self.name = self.data:GetStringOrDefault( "name", "" )
	self.blueprint = self.data:GetString( "blueprint" )
    
    if self.searchTarget ~= "" then
        self.searchTarget = FindService:FindEntityByName( self.searchTarget )
    end

	LogService:Log( "campaign_objective_construct_building:init() - type :" .. self.type )
	LogService:Log( "campaign_objective_construct_building:init() - blueprint :" .. self.blueprint )
	LogService:Log( "campaign_objective_construct_building:init() - name: " .. self.name )
	LogService:Log( "campaign_objective_construct_building:init() - progressMax:" .. tostring(  self.progressMax ) )	
	LogService:Log( "campaign_objective_construct_building:init() - search radius and search target are not set : init as global search" )	

	self.data:SetInt( "progress_current", 0 )
end

function campaign_objective_construct_building:DebugCounter( currentCount, info )	
	local progressCurrent = self.data:GetInt( "progress_current" )

	if ( progressCurrent ~= currentCount ) then
		LogService:Log( info )
	end
end

function campaign_objective_construct_building:GetCurrentCounter()
	
	if ( self.type ~= "" ) then
		local count = BuildingService:GetBuildingByTypeCount( self.type )		
		self:DebugCounter( count, "campaign_objective_construct_building:GetCurrentCounter() - BuildingService:GetBuildingByTypeCount : " .. self.type .. " count : " .. tostring( count ) )
		return count
	elseif ( self.blueprint ~= "" ) then
		local count = BuildingService:GetBuildingByBpCount( self.blueprint )
		self:DebugCounter( count, "campaign_objective_construct_building:GetCurrentCounter() - BuildingService:GetBuildingByBpCount : " .. self.blueprint .. " count : " .. tostring( count ) )
		return count
	elseif ( self.name ~= "" ) then
		local count = BuildingService:GetBuildingByNameCount( self.name )
		self:DebugCounter( count, "campaign_objective_construct_building:GetCurrentCounter() - BuildingService:GetBuildingByNameCount : " .. self.name .. " count : " .. tostring( count ) )
		return count
	end 	

	return 0
end


function campaign_objective_construct_building:onUpdate()

	local progressCurrent = self:GetCurrentCounter()

    if ( progressCurrent >= self.progressMax ) then
	   ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   progressCurrent = self.progressMax
	   self.fsm:ChangeState( "idle" )
    end

	self.data:SetInt( "progress_current", progressCurrent )

end

return campaign_objective_construct_building
