class 'time_repair' ( LuaEntityObject )

function time_repair:__init()
	LuaEntityObject.__init(self,self)
end

function time_repair:init()
    self.parent = EntityService:GetParent( self.entity )
    self.interval = self.data:GetFloatOrDefault("interval", 0.1)
    local repairMinTime = self.data:GetFloatOrDefault("repair_min_time", 5)
    local buildTimeScale = self.data:GetFloatOrDefault("build_time_scale", 0.2)
    local healthScale = self.data:GetIntOrDefault("use_health_sale", 1 )
    self.effectEveryNHeal = 5
    self.currentHeal = 0
    self.cubeEnt = INVALID_ID

    local currentHealth = HealthService:GetHealth( self.parent )
    local maxHealth = HealthService:GetMaxHealth( self.parent )
    local buildTime =  BuildingService:CalculateBuildTime( self.parent );

    local percent = currentHealth / maxHealth
    local activationsPercent = 1.0
    local database = EntityService:GetDatabase( self.parent )
    self.hasActivations = false
    if ( database and database:HasInt("number_of_activations")) then
		healthScale = 0
		local currentNumberOfActivations =  database:GetInt("number_of_activations")
        local blueprintDatabase = EntityService:GetBlueprintDatabase( self.parent )
        local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")
        self.hasActivations = maxNumberOfActivations > currentNumberOfActivations
		activationsPercent = 1.0 - ( currentNumberOfActivations / maxNumberOfActivations )
        if ( database:HasFloat( "repair_time")) then
            buildTime = database:GetFloat("repair_time")
            buildTimeScale = 1.0
        end
    end

    local time = 0.0
    if ( healthScale == 0 ) then
        time = (buildTime * buildTimeScale) * activationsPercent
    else
        time = (buildTime * buildTimeScale) * ( 1.0 - percent )
    end
    
	self.repairTime = math.max( repairMinTime , time )
    
	local step = self.repairTime / self.interval
    local missingHealth = maxHealth - currentHealth
    self.repairAmount = missingHealth / step

    self.player = self.data:GetIntOrDefault("player",-1 )

    local canAffordRepair = false
    if ( self.player == -1 ) then
        canAffordRepair = BuildingService:PayRepairCosts( self.parent, 0, self.repairAmount )
    else
        canAffordRepair = BuildingService:PayRepairCosts( self.parent, self.player, self.repairAmount )
    end

    self.cubeReachBuilding = false
    self.cleanup = false
    self.timer = nil

    local database = EntityService:GetDatabase( self.parent )

    if (canAffordRepair and EntityService:IsAlive( self.parent) ) then
    	self:RegisterHandler( self.parent, "DamageEvent", "OnDamageEvent" )
	    self:RegisterHandler( self.parent, "DestroyRequest", "OnDestroyRequest" )
        self.healMachine = self:CreateStateMachine()
	    self.healMachine:AddState( "healing", { enter="OnHealStart", execute="OnHealExecute", exit="OnHealEnd", interval=self.interval } )
        if self.player ~= -1 then
            local cubes =  BuildingService:FlyCubesToBuilding(self.parent, self.player, true , false)		
            self.cubeEnt = cubes.first
            self.endCubeEnt = cubes.second
	        if ( AnimationService:HasAnim( self.cubeEnt, "fly_and_scale") ) then
	        	AnimationService:StartAnim( self.cubeEnt, "fly_and_scale", false, 4 )
	        end
	        EffectService:AttachEffects(self.cubeEnt, "fly")
            self:RegisterHandler( self.cubeEnt, "MoveEndEvent", "OnMoveEndEvent" )
        end
        
    else
        self.cleanup = true
        EntityService:RemoveEntity(self.entity)
    end
end

function  time_repair:OnHealStart( state )
    self.timer = BuildingService:AttachGuiTimerWithMaterial( self.parent, self.repairTime, true, "gui/hud/bars/repair_timer")
    state:SetDurationLimit( self.repairTime )
end

function time_repair:OnMoveEndEvent( evt )
	self.cubeReachBuilding = true
    self.healMachine:ChangeState("healing")
end

function  time_repair:Cleanup()
    if ( self.cleanup == true ) then return end

    if ( EntityService:IsAlive( self.cubeEnt ) ) then
	    AnimationService:StartAnim( self.cubeEnt, "scale_down", false )
	    EntityService:CreateLifeTime( self.cubeEnt, 0.5, "" ) 
    end

    if ( EntityService:IsAlive( self.endCubeEnt ) ) then
        EntityService:RemoveEntity(self.endCubeEnt)
    end

    if ( self.timer ~= nil and EntityService:IsAlive(self.timer) ) then
        EntityService:RemoveEntity(self.timer)
    end

    self.cleanup = true
end

function  time_repair:OnHealExecute( state, dt)

    HealthService:AddHealthInUnits( self.parent, self.repairAmount )
    if ( self.currentHeal % self.effectEveryNHeal == 0) then
        QueueEvent("AttachEffectGroupRequest", self.parent, "repair", 0.0 );
    end
 
    self.currentHeal = self.currentHeal + 1
    if ( HealthService:GetHealthInPercentage( self.parent ) >= 1.0 and self.hasActivations ~= true ) then
        state:Exit()
    end
end

function  time_repair:OnHealEnd()
    HealthService:AddHealthInPercentage( self.parent, 100.0 )
    if (self.hasActivations == true ) then
        local database = EntityService:GetDatabase( self.parent )
        self.hasActivations = false
        if ( database and database:HasInt("number_of_activations")) then
        local blueprintDatabase = EntityService:GetBlueprintDatabase( self.parent )
            local maxNumberOfActivations = blueprintDatabase:GetInt("number_of_activations")
            database:SetInt("number_of_activations", maxNumberOfActivations)
        end
    end
    self:Cleanup()
    EntityService:RemoveEntity(self.entity)
end


function time_repair:OnDamageEvent(evt)
    self:Cleanup()
    EntityService:RemoveEntity(self.entity)
end

function time_repair:OnDestroyRequest(evt)
    self:Cleanup()
    EntityService:RemoveEntity(self.entity)
end

function time_repair:OnRelease()
    self:Cleanup()
end

return time_repair
 