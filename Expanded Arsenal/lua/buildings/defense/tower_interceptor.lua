-- lua by Piisfun, edited by WirawanMYT

local tower = require("lua/buildings/defense/tower.lua")

class 'tower_interceptor' (tower)

function tower_interceptor:__init()
	tower.__init(self, self)
end

function tower_interceptor:OnInit()

	self:RegisterHandler(self.entity, "TurretEvent", "OnTurretEvent")

	--Master State Machine setup
	self.fsm = self:CreateStateMachine();
	self.fsm:AddState("TowerOperate", {enter = "OnTowerStart", exit = "OnTowerStop"});
	self.fsm:AddState("TowerReload", {enter = "OnTowerReload", exit = "OnTowerReloadEnd"});
	
	--Variables for timers
	self.intercept_time = self.data:GetFloatOrDefault("intercept_time", 5)
	self.reload_time = self.data:GetFloatOrDefault("reload_time", 1.5)
	
	--Variable Intercept Range. Assign in Projectile, Artillery, Grenade format
	local intercept_ranges = self.data:GetStringOrDefault("intercept_ranges", "")
	intercept_ranges = Split(intercept_ranges, ",")
	
	--Get Component list. Assign in Projectile, Artillery, Grenade format
	local target_components = self.data:GetStringOrDefault("intercept_target_components", "")
	target_components = Split(target_components, ",")
	
	--Get rates. Assign in Projectile, Artillery, Grenade format
	local intercept_intervals = self.data:GetStringOrDefault("intercept_rates", "")
	intercept_intervals = Split(intercept_intervals, ",")
	
	--State machine variable:
	self.state_machines = {} --This will be a list of all the state machines
	--Self.intercept_interval is now a table of strings representing durations. We want those as numbers...
	for i = 1, #(target_components) do
	
		--check that the interval exists. Index array to assign variables in Projectile, Artillery, Grenade format
		if intercept_intervals[i] and intercept_ranges[i] then --will only be false if it is missing
			if target_components[i] == "ProjectileAmmoComponent" or target_components[i] == "Projectile" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnProjectileIntercept", interval = 1 / tonumber(intercept_intervals[i])}) -- division for internal value used by script
				self.intercept_range_projectile = tonumber(intercept_ranges[i])
				self.interceptor_effect_projectile = self.data:GetStringOrDefault("interceptor_effect_projectile" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_projectile = self.data:GetStringOrDefault("interceptor_hit_effect_projectile" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
				
			elseif target_components[i] == "ArtilleryAmmoComponent" or target_components[i] == "Artillery" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnArtilleryIntercept", interval = 1 / tonumber(intercept_intervals[i])})
				self.intercept_range_artillery = tonumber(intercept_ranges[i])
				self.interceptor_effect_artillery = self.data:GetStringOrDefault("interceptor_effect_artillery" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_artillery = self.data:GetStringOrDefault("interceptor_hit_effect_artillery" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
				
			elseif target_components[i] == "GrenadeAmmoComponent" or target_components[i] == "Grenade" then
				self.state_machines[i] = self:CreateStateMachine()
				self.state_machines[i]:AddState("intercept", {execute = "OnGrenadeIntercept", interval = 1 / tonumber(intercept_intervals[i])})
				self.intercept_range_grenade = tonumber(intercept_ranges[i])
				self.interceptor_effect_grenade = self.data:GetStringOrDefault("interceptor_effect_grenade" , "effects/buildings_and_machines/drone_defensive_lightning")
				self.interceptor_hit_effect_grenade = self.data:GetStringOrDefault("interceptor_hit_effect_grenade" , "effects/buildings_and_machines/drone_defensive_lightning_hit")
			end
		end
	end
end


function tower_interceptor:OnActivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	EffectService:AttachEffects(self.entity, "intercept_on")
	self.powered = true
	
	--Start State Machine
	if not self.reloading then --This check prevents bypassing the reload by power cycling rapidly.
		self.fsm:ChangeState("TowerOperate")
	end
end

function tower_interceptor:OnDeactivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")
	self.powered = false
	
	--Stop core loop
	local state = self.fsm:GetState("TowerOperate") 
	if state ~= nil then 
		state:Exit()
	end
end


function tower_interceptor:OnTowerStart(state)
	--Start up interceptors
	for i = 1, #(self.state_machines) do
		self.state_machines[i]:ChangeState("intercept")
	end
	
	self.timer_latch = true
end

function tower_interceptor:OnTowerStop(state)
    state:ClearDurationLimit()
	
	--Shut down interceptors
	for i = 1, #(self.state_machines) do
		local state = self.state_machines[i]:GetState("intercept") 
		if state ~= nil then 
			state:Exit() 
		end	
	end
	
	self.fsm:ChangeState("TowerReload")
end

function tower_interceptor:OnTowerReload(state)
	state:SetDurationLimit(self.reload_time)
	self.reloading = true
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_on")
	EffectService:AttachEffects(self.entity, "intercept_off")
end

function tower_interceptor:OnTowerReloadEnd(state)
	
	EffectService:DestroyEffectsByGroup(self.entity, "intercept_off")
	
	if self.powered then
		self.fsm:ChangeState("TowerOperate")
		EffectService:AttachEffects(self.entity, "intercept_on")
	end
	
	self.reloading = false
end


function tower_interceptor:OnProjectileIntercept(state)
	
	local predicate = {
		signature = "ProjectileAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt(0), entity, "hostility")
		end
	};
	self:OnIntercept(state, predicate, self.intercept_range_projectile, self.interceptor_effect_projectile, self.interceptor_hit_effect_projectile)
end

function tower_interceptor:OnArtilleryIntercept(state)
	
	local predicate = {
		signature = "ArtilleryAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt(0), entity, "hostility")
		end
	};
	self:OnIntercept(state, predicate, self.intercept_range_artillery, self.interceptor_effect_artillery, self.interceptor_hit_effect_artillery)
end

function tower_interceptor:OnGrenadeIntercept(state)
	
	local predicate = {
		signature = "GrenadeAmmoComponent",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt(0), entity, "hostility")
		end
	};
	self:OnIntercept(state, predicate, self.intercept_range_grenade, self.interceptor_effect_grenade, self.interceptor_hit_effect_grenade)
end


function tower_interceptor:OnIntercept(state, predicate, range, effect, hit_effect)
	local entities = FindService:FindEntitiesByPredicateInRadius(self.entity, range, predicate);
    local target = FindClosestEntity(self.entity, entities);
    if target == INVALID_ID then
        return
    end
	
	self:ShootLightningAtTarget(target, predicate.signature, effect, hit_effect)
	--Start timer on first intercept.
	if self.timer_latch then
		local master_state = self.fsm:GetState("TowerOperate")
		master_state:SetDurationLimit(self.intercept_time)
		
		self.timer_latch = false
	end
end


function tower_interceptor:ShootLightningAtTarget(target_entity, target_component, effect, hit_effect)
	
	AnimationService:StartAnim( self.entity, "working", false)
	
    local tower_position = EntityService:GetPosition(self.entity)
    local target_position = EntityService:GetPosition(target_entity)
	
    local lightning = EntityService:SpawnEntity(effect, self.entity, "att_energy", "")
    local component = reflection_helper(EntityService:GetComponent(lightning, "LightningComponent"))
	
	local tower_lightning_position = EntityService:GetPosition(lightning)
	
    local container = rawget(component.lighning_vec, "__ptr");
    local instance =  reflection_helper(container:CreateItem())
	
    local direction = VectorMulByNumber(Normalize(VectorSub(target_position, tower_position)), 2.0)
    tower_position = VectorAdd(tower_lightning_position, direction)
	
    instance.start_point.x = tower_position.x
    instance.start_point.y = tower_position.y
    instance.start_point.z = tower_position.z
	
    instance.end_point.x = target_position.x
    instance.end_point.y = target_position.y
    instance.end_point.z = target_position.z
	
    local projectile_effect = self:GetProjectileHitEffect(target_entity, target_component)
    if projectile_effect ~= nil then
        EntityService:SpawnEntity(projectile_effect, target_position.x, target_position.y, target_position.z, "")
    else
        EntityService:SpawnEntity(hit_effect, tower_position.x, tower_position.y, tower_position.z, "")
    end

    EntityService:RemoveEntity(target_entity)

end

function tower_interceptor:GetProjectileHitEffect(target_entity, target_component)
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
	
	if component.on_enemy_hit_effect ~= "" then
        return component.on_enemy_hit_effect
    end

    return nil
end

return tower_interceptor
