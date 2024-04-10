-- lua by Piisfun, edited by WirawanMYT

local tower = require("lua/buildings/defense/tower.lua")

class 'tower_charge' (tower)

function tower_charge:__init()
	tower.__init(self,self)
end

function tower_charge:OnInit()

	self:RegisterHandler(self.entity, "TurretEvent", "OnTurretEvent")
	self.working_anim = self.data:GetIntOrDefault("animation_type", 1)
	
	-- Timing parameters
	
	self.charge_time = self.data:GetFloatOrDefault("charge_time", 3)
	self.attack_time = self.data:GetFloatOrDefault("attack_time", 3)
	self.reload_time = self.data:GetFloatOrDefault("reload_time", 1.5)
	
	-- Statemachines
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("TowerDetect", {execute = "Loop_Detect", interval = 0.1})
	self.fsm:AddState("TowerCharge", {enter = "Start_Charge", exit = "End_Charge"})
	self.fsm:AddState("TowerAttack", {enter = "Start_Attack", execute = "Loop_Attack", exit = "End_Attack"})
	self.fsm:AddState("TowerReload", {enter = "Start_Reload", exit = "End_Reload"})
end

function tower_charge:OnBuildingEnd()

	if EntityService:HasComponent(self.entity, "TurretComponent") then
		local T_desc = reflection_helper(rawget(reflection_helper(EntityService:GetComponent(self.entity, "TurretComponent")).turret_desc, "__ptr"))
		self.firing_range = T_desc.aim_volume.range_max
	else
		self.firing_range = 1
        QueueEvent("SellBuildingRequest", self.entity, 0, false)
	end
	
	EntityService:RemoveComponent(self.entity, "TowerComponent")
end

function tower_charge:OnActivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.powered = true
	
	if not self.reloading then
		self.fsm:ChangeState("TowerDetect")
	end
end

function tower_charge:OnDeactivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	self.powered = false
	
	local state = self.fsm:GetState("TowerDetect")
	if state ~= nil then
		state:Exit()
	end
	
	local state1 = self.fsm:GetState("TowerCharge")
	if state1 ~= nil then
		state:Exit()
	end
	
	local state2 = self.fsm:GetState("TowerAttack")
	if state2 ~= nil then
		state:Exit()
	end
end

local target_locked = 4 -- static variable

function tower_charge:OnTurretEvent(evt)

	if evt:GetTurretStatus() == target_locked then
		self.targeting = true
	else
		self.targeting = false
	end
end

function tower_charge:Loop_Detect(state)
	if self.targeting then
		self.fsm:ChangeState("TowerCharge")
	end
end

function tower_charge:Start_Charge(state)
	state:SetDurationLimit(self.charge_time)
	EffectService:AttachEffects(self.entity, "charge")
	
	if (self.working_anim == 1) then
		AnimationService:StartAnim( self.entity, "working")
	elseif (self.working_anim == 2) then
		AnimationService:StartAnim( self.entity, "working")
	else
		return
	end
end

function tower_charge:End_Charge(state)
	EffectService:DestroyEffectsByGroup(self.entity, "charge")
	if self.powered then
		self.fsm:ChangeState("TowerAttack")
		
		if (self.working_anim == 2 )then
			AnimationService:StopAnim( self.entity, "working")
		else
			return	
		end
	end
end

function tower_charge:Start_Attack(state)
	state:SetDurationLimit(self.attack_time)
	EffectService:AttachEffects(self.entity, "weapon_primed")
end

function tower_charge:Loop_Attack(state)
	local targets = FindService:FindEntitiesByPredicateInRadius(self.entity, self.firing_range, self.predicate)
	
	if #targets > 0 and self.targeting and (not self.attacking) then
		self.attacking = true
		WeaponService:StartShoot(self.entity)
		EffectService:DestroyEffectsByGroup(self.entity, "weapon_primed")
	elseif (not self.targeting) and self.attacking then
		self.attacking = false
		WeaponService:StopShoot(self.entity)
		EffectService:AttachEffects(self.entity, "weapon_primed")
	end
end

function tower_charge:End_Attack(state)
	self.fsm:ChangeState("TowerReload")
	self.attacking = false
	WeaponService:StopShoot(self.entity)
	EffectService:DestroyEffectsByGroup(self.entity, "weapon_primed")
end

function tower_charge:Start_Reload(state)
	state:SetDurationLimit(self.reload_time)
	EffectService:AttachEffects(self.entity, "reload")
	
	if self.working_anim == 1 then
		AnimationService:StopAnim( self.entity, "working" )
	else
		return
	end
	
	self.reloading = true
end

function tower_charge:End_Reload(state)
	
	EffectService:DestroyEffectsByGroup(self.entity, "reload")
	
	if self.powered then
		self.fsm:ChangeState("TowerDetect")
	end
	
	self.reloading = false
end

return tower_charge