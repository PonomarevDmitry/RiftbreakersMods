local item = require("lua/units/ground/arachnoid_sentinel_base.lua")
require("lua/utils/table_utils.lua")

class 'arachnoid_boss_intercept' ( arachnoid_sentinel_base )

function arachnoid_boss_intercept:__init()
	arachnoid_sentinel_base.__init(self,self)
end

function arachnoid_boss_intercept:OnInit()
	self:RegisterHandler( self.entity, "SpawnerInfoRequest",  "OnSpawnerInfoRequest" )

	arachnoid_sentinel_base.OnInit(self)

	self.armour = EntityService:SpawnAndAttachEntity( "units/ground/arachnoid_boss_armour", self.entity, "att_armor", "" )
	
	--Master State Machine setup
	self.fsm = self:CreateStateMachine();
	self.fsm:AddState("OperateIntercept", {enter = "OnStartIntercept", exit = "OnStopIntercept"});
	self.fsm:AddState("ReloadIntercept", {enter = "OnReloadInterceptStart", exit = "OnReloadInterceptEnd"});
	self.fsm:ChangeState("OperateIntercept")
	
	--Variables for timers
	self.intercept_time = self.data:GetFloatOrDefault("intercept_time_" .. DifficultyService:GetCurrentDifficultyName(), 3)
	self.reload_time = self.data:GetFloatOrDefault("reload_time_" .. DifficultyService:GetCurrentDifficultyName(), 3)
	
	-- Variable Intercept Range. Assign in Projectile, Artillery, Grenade format
	local intercept_ranges = self.data:GetStringOrDefault("intercept_ranges_" .. DifficultyService:GetCurrentDifficultyName() , "") 
	intercept_ranges = Split(intercept_ranges,",")
	
	--Get Component list. Assign in Projectile, Artillery, Grenade format
	local target_components = self.data:GetStringOrDefault("intercept_target_components_" .. DifficultyService:GetCurrentDifficultyName() , "")
	target_components = Split(target_components, ",")
	
	--Get rates. Assign in Projectile, Artillery, Grenade format
	local intercept_intervals = self.data:GetStringOrDefault("intercept_rates_" .. DifficultyService:GetCurrentDifficultyName() , "")
	intercept_intervals = Split(intercept_intervals, ",")
	
	--State machine variable:
	self.state_machines = {}
	--Self.intercept_interval is now a table of strings representing durations. We want those as numbers...
	for i = 1, #(target_components) do
	
		--check that the interval exists. Index array to assign variables in Projectile, Artillery, Grenade format
		if intercept_intervals[i] and intercept_ranges[i] then --will only be false if it is missing
			if target_components[i] == "ProjectileAmmoComponent" or target_components[i] == "Projectile" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnProjectileIntercept", interval = 1 / tonumber(intercept_intervals[i])}) -- division for internal value used by script
				self.state_machines[i]:ChangeState("intercept")
				self.intercept_range_projectile = tonumber(intercept_ranges[i])
				self.interceptor_effect_projectile = self.data:GetStringOrDefault("interceptor_effect_projectile" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_projectile = self.data:GetStringOrDefault("interceptor_hit_effect_projectile" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
				
			elseif target_components[i] == "ArtilleryAmmoComponent" or target_components[i] == "Artillery" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnArtilleryIntercept", interval = 1 / tonumber(intercept_intervals[i])})
				self.state_machines[i]:ChangeState("intercept")
				self.intercept_range_artillery = tonumber(intercept_ranges[i])
				self.interceptor_effect_artillery = self.data:GetStringOrDefault("interceptor_effect_artillery" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_artillery = self.data:GetStringOrDefault("interceptor_hit_effect_artillery" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
				
			elseif target_components[i] == "GrenadeAmmoComponent" or target_components[i] == "Grenade" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnGrenadeIntercept", interval = 1 / tonumber(intercept_intervals[i])})
				self.state_machines[i]:ChangeState("intercept")
				self.intercept_range_grenade = tonumber(intercept_ranges[i])
				self.interceptor_effect_grenade = self.data:GetStringOrDefault("interceptor_effect_grenade" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_grenade = self.data:GetStringOrDefault("interceptor_hit_effect_grenade" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
			end
		end
	end
end

function  arachnoid_boss_intercept:OnStartIntercept(state)
	--Start up interceptors
	for i = 1, #(self.state_machines) do
		self.state_machines[i]:ChangeState("intercept")
	end
	
	self.timer_latch = true
	
	EffectService:AttachEffects(self.entity, "intercept_on")
end

function  arachnoid_boss_intercept:OnStopIntercept(state)
    state:ClearDurationLimit()
	
	--Shut down interceptors
	for i = 1, #(self.state_machines) do
		local state = self.state_machines[i]:GetState("intercept") 
		if state ~= nil then 
			state:Exit() 
		end	
	end
	
	self.fsm:ChangeState("ReloadIntercept")
	
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
end

function  arachnoid_boss_intercept:OnReloadInterceptStart(state)
	state:SetDurationLimit(self.reload_time)
	self.reloading = true

	EffectService:AttachEffects(self.entity, "intercept_off")
end

function  arachnoid_boss_intercept:OnReloadInterceptEnd(state)
	
	if HealthService:IsAlive(self.entity) then
		self.fsm:ChangeState("OperateIntercept")
	end
	
	self.reloading = false
	
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")
end

function arachnoid_boss_intercept:OnProjectileIntercept(state)
	local predicate = {
		signature = "ProjectileAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(self.entity, entity, "hostility")
		end}
	self:OnIntercept(state, predicate, self.intercept_range_projectile, self.interceptor_effect_projectile, self.interceptor_hit_effect_projectile)
end

function arachnoid_boss_intercept:OnArtilleryIntercept(state)
	local predicate = {
		signature = "ArtilleryAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(self.entity, entity, "hostility")
		end}
	self:OnIntercept(state, predicate, self.intercept_range_artillery, self.interceptor_effect_artillery, self.interceptor_hit_effect_artillery)
end

function arachnoid_boss_intercept:OnGrenadeIntercept(state)
	local predicate = {
		signature = "GrenadeAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(self.entity, entity, "hostility")
		end}
	self:OnIntercept(state, predicate, self.intercept_range_grenade, self.interceptor_effect_grenade, self.interceptor_hit_effect_grenade)
end


function arachnoid_boss_intercept:OnIntercept(state, predicate, range, effect, hit_effect)
	local entities = FindService:FindEntitiesByPredicateInRadius(self.entity, range, predicate);
    local target = FindClosestEntity(self.entity, entities);
    if target == INVALID_ID then
        return
    end
	
	if self.timer_latch then
		local master_state = self.fsm:GetState("OperateIntercept")
		master_state:SetDurationLimit(self.intercept_time)
		
		self.timer_latch = false
	end

	self:ShootLightningAtTarget(target, predicate.signature, effect, hit_effect)
end

function arachnoid_boss_intercept:ShootLightningAtTarget(target_entity, target_component, effect, hit_effect)
	
    local unit_self_position = EntityService:GetPosition(self.entity)
    local unit_target_position = EntityService:GetPosition(target_entity)
	
    local lightning = EntityService:SpawnEntity(effect, self.entity, "att_death","")
    local component = reflection_helper(EntityService:GetComponent(lightning, "LightningComponent"))
	
	local unit_lightning_position = EntityService:GetPosition(lightning)
	
    local container = rawget(component.lighning_vec, "__ptr");
    local instance =  reflection_helper(container:CreateItem())
	
    local direction = VectorMulByNumber(Normalize(VectorSub(unit_target_position, unit_self_position)), 2.0)
    unit_self_position = VectorAdd(unit_lightning_position, direction)
	
    instance.start_point.x = unit_self_position.x
    instance.start_point.y = unit_self_position.y
    instance.start_point.z = unit_self_position.z
	
    instance.end_point.x = unit_target_position.x
    instance.end_point.y = unit_target_position.y
    instance.end_point.z = unit_target_position.z
	
    local projectile_effect = self:GetProjectileHitEffect(target_entity, target_component)
    if projectile_effect ~= nil then
        EntityService:SpawnEntity(projectile_effect, unit_target_position.x, unit_target_position.y, unit_target_position.z, "")
    else
        EntityService:SpawnEntity(hit_effect, unit_self_position.x, unit_self_position.y, unit_self_position.z, "")
    end

    EntityService:RemoveEntity(target_entity)

end

function arachnoid_boss_intercept:GetProjectileHitEffect(target_entity, target_component)
    local projectile = EntityService:GetComponent(target_entity, target_component)
    if projectile == nil then
        return nil
    end

    local component = reflection_helper(projectile)
    if component.on_resisted_hit_effect ~= "" then
        return component.on_resisted_hit_effect
    end
	
    if component.on_world_hit_effect ~= "" then
        return component.on_world_hit_effect
    end
end

function arachnoid_boss_intercept:_OnDestroyRequest( evt )

	EntityService:ChangeToWreck( self.entity, evt:GetDamageType(), evt:GetDamagePercentage(),self.wreck_type, self.wreckMinSpeed )
	self:ChangeSoundState("idle")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")

    if self.OnDestroyRequest then
        self:OnDestroyRequest(evt)
    end
end

function arachnoid_boss_intercept:OnAnimationMarkerReached(evt)
	if ( arachnoid_sentinel_base.OnAnimationMarkerReached ) then
		arachnoid_sentinel_base.OnAnimationMarkerReached( self, evt )
    end
	
	if ( evt:GetMarkerName() == "mrk_footstep_fl" ) then
		EffectService:AttachEffects( self.entity, "footstep_fl" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_fr" ) then
		EffectService:AttachEffects( self.entity, "footstep_fr" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_rl" ) then
		EffectService:AttachEffects( self.entity, "footstep_fl" )
	elseif ( evt:GetMarkerName() == "mrk_footstep_rr" ) then
		EffectService:AttachEffects( self.entity, "footstep_rr" )
	end

	return true
end

function arachnoid_boss_intercept:OnDamageEvent(evt)
	if ( arachnoid_sentinel_base.OnDamageEvent ) then
		arachnoid_sentinel_base.OnDamageEvent( self, evt )
	end
	
	if self.armour ~= nil then
		if HealthService:GetHealthInPercentage( self.entity ) < 0.5 then
			EntityService:RequestDestroyPattern( self.armour, "default" )
			--EntityService:SetSubMeshMaterial( self.entity, "unlit/null", 1, "" )
			self.armour = nil
		end
	end
end

function arachnoid_boss_intercept:OnSpawnerInfoRequest( evt )
	SoundService:PlayAnnouncement( "voice_over/announcement/warning_nest_wave_spawn", 20 ) 
end

return arachnoid_boss_intercept
