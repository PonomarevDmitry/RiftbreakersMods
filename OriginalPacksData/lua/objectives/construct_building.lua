class 'construct_building' ( LuaObjectiveScript )

function construct_building:__init()
	LuaObjectiveScript.__init(self,self)
end

function construct_building:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="onUpdate" } )
	self.fsm:AddState( "idle", {} )
	self.fsm:ChangeState( "update" )

    self.progressMax = self.data:GetInt( "progress_max" )
	self.type = self.data:GetStringOrDefault( "type", "" )
	self.name = self.data:GetStringOrDefault( "name", "" )
	self.blueprint = self.data:GetString( "blueprint" )

    self.searchRadius = self.data:GetFloat( "search_radius" )
    self.searchTarget = self.data:GetString( "search_target" )
    
    if self.searchTarget ~= "" then
        self.searchTarget = FindService:FindEntityByName( self.searchTarget )
    end

	LogService:Log( "construct_building:init() - type :" .. self.type )
	LogService:Log( "construct_building:init() - blueprint :" .. self.blueprint )
	LogService:Log( "construct_building:init() - name: " .. self.name )
	LogService:Log( "construct_building:init() - progressMax:" .. tostring(  self.progressMax ) )
	LogService:Log( "construct_building:init() - search_radius: " .. tostring( self.searchRadius ) )
	LogService:Log( "construct_building:init() - search_target:" .. self.searchTarget )

	if ( ( self.searchRadius > 0 ) and ( self.searchTarget ~= "" ) ) then
		LogService:Log( "construct_building:init() - search radius and search target are set : init as local search" )
	else
		LogService:Log( "construct_building:init() - search radius and search target are not set : init as global search" )
	end

	self.data:SetInt( "progress_current", 0 )
end

function construct_building:DebugCounter( currentCount, info )	
	local progressCurrent = self.data:GetInt( "progress_current" )

	if ( progressCurrent ~= currentCount ) then
		LogService:Log( info )
	end
end

function construct_building:GetCurrentCounter()

	if ( ( self.searchRadius > 0 ) and ( self.searchTarget ~= INVALID_ID ) ) then
		if ( self.type ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByType( self.searchTarget, self.type, self.searchRadius )		
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetFinishedBuildingByType : " .. self.type .. " count : " .. tostring( #count ) )
			return #count
		elseif ( self.blueprint ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByBp( self.searchTarget, self.blueprint, self.searchRadius )
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetFinishedBuildingByBp : " .. self.blueprint .. " count : " .. tostring( #count ) )
			return #count
		elseif ( self.name ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByName( self.searchTarget, self.name, self.searchRadius )
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetFinishedBuildingByName : " .. self.name .. " count : " .. tostring( #count ) )
			return #count
		end 
	else
		if ( self.type ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByType( self.type )		
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetBuildingByTypeCount : " .. self.type .. " count : " .. tostring( count ) )
			return #count
		elseif ( self.blueprint ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByBp( self.blueprint )
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetBuildingByBpCount : " .. self.blueprint .. " count : " .. tostring( count ) )
			return #count
		elseif ( self.name ~= "" ) then
			local count = BuildingService:GetFinishedBuildingByName( self.name )
			self:DebugCounter( #count, "construct_building:GetCurrentCounter() - BuildingService:GetBuildingByNameCount : " .. self.name .. " count : " .. tostring( count ) )
			return #count
		end 	
	end


	return 0
end


function construct_building:onUpdate()

	local progressCurrent = self:GetCurrentCounter()

    if ( progressCurrent >= self.progressMax ) then
	   ObjectiveService:FinishObjectiveByObjectiveId( self.objective_id, OBJECTIVE_SUCCESS )
	   progressCurrent = self.progressMax
	   self.fsm:ChangeState( "idle" )
    end

	self.data:SetInt( "progress_current", progressCurrent )

end

return construct_building
