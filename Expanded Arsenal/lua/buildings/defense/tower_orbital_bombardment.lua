local tower = require("lua/buildings/defense/tower.lua")

class 'tower_orbital_bombardment' (tower)

function tower_orbital_bombardment:__init()
	tower.__init(self,self)
end

function tower_orbital_bombardment:OnInit()

	self.range = self.data:GetFloatOrDefault("range", 35)
	self.reload = self.data:GetIntOrDefault("reload", 10)
	self.weapon = self.data:GetStringOrDefault("bombardment", "items/skills/orbital_bombardment_advanced")
	self.marker = self.data:GetStringOrDefault("marker", "effects/enemies_gnerot/spike_warning")

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("TowerActive", {execute = "Loop_Active", exit = "End_Active", interval = 0.1})
	self.fsm:AddState("TowerReload", {enter = "Start_Reload", exit = "End_Reload"})
end


function tower_orbital_bombardment:OnBuildingStart()
	self.fire = nil
	self.target_position = nil
end

function tower_orbital_bombardment:OnActivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	
	self.powered = true
	
	if not self.reloading then
		self.fsm:ChangeState("TowerActive")
	end
end

function tower_orbital_bombardment:OnDeactivate()
	self:OperateLight(EnvironmentService:GetTimeOfDay())
	
	self.powered = false
	
	local state = self.fsm:GetState("TowerActive")
	if state ~= nil then
		state:Exit()
	end
end


function tower_orbital_bombardment:Loop_Active(state)

	self.predicate = {
		signature = "TeamComponent",
		type="ground_unit",
		filter = function(entity)
			return EntityService:IsInTeamRelation(PlayerService:GetPlayerControlledEnt( 0 ), entity, "hostility")
		end
	};

	local target = FindClosestEntity(self.entity, FindService:FindEntitiesByPredicateInRadius(self.entity, self.range, self.predicate))
	if target == INVALID_ID then return	end
	
	self.target_position = EntityService:GetPosition(target)
	
	self.fsm:ChangeState("TowerReload")
end

function tower_orbital_bombardment:End_Active(state)

	if not self.powered then return end
	
	EntityService:SpawnEntity(self.marker, self.target_position, EntityService:GetTeam(self.entity))
	self.target_position.y = self.target_position.y + 30
	
	self.fire = EntityService:SpawnEntity(self.weapon, self.target_position, EntityService:GetTeam(self.entity))
	
	WeaponService:UpdateWeaponStatComponent(self.fire, self.fire)
	WeaponService:StartShoot(self.fire)
	
	self.target_position = nil
	
end

function tower_orbital_bombardment:Start_Reload(state)

	BuildingService:AttachGuiTimer(self.entity, self.reload, true)
	state:SetDurationLimit(self.reload)

	self.reloading = true
end

function tower_orbital_bombardment:End_Reload(state)

	self.reloading = false
	
	if self.powered then
		self.fsm:ChangeState("TowerActive")
	end
end

return tower_orbital_bombardment