class 'weather_generic' ( LuaGraphNode )

function weather_generic:__init()
    LuaGraphNode.__init(self,self)
end

function weather_generic:init()
	self.fsm = self:CreateStateMachine()
    self.fsm:AddState( "wait", { from="*", enter="OnEnterWait", exit= "OnExitWait" } )
end

function weather_generic:Activated()
	self.fsm:ChangeState("wait")	
end

function weather_generic:OnEnterWait( state )
	local minLifeTime = 20
	local maxLifeTime = 30	
	
	if ( self.data:HasInt( "min_life_time" ) ) then 
		minLifeTime = self.data:GetInt( "min_life_time" )
	end

	if ( self.data:HasInt( "max_life_time" ) ) then 
		maxLifeTime = self.data:GetInt( "max_life_time" )
	end
	
	local lifeTime = math.random( minLifeTime, maxLifeTime )
	local weatherBlueprint = self.data:GetString( "weather_blueprint" )		
	local weatherEnt = EntityService:CreateEntity( weatherBlueprint )
	EntityService:CreateLifeTime( weatherEnt, lifeTime, "" )
    state:SetDurationLimit( lifeTime )
	
	self.newName = self.data:GetStringOrDefault("new_name", "")
	if self.newName ~= "" then
		EntityService:SetName( weatherEnt, self.newName  )
	end
end

function weather_generic:OnExitWait( state )
    self:SetFinished()
end

return weather_generic