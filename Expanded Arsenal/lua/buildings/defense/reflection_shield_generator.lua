-- lua by Piisfun, edited by WirawanMYT

require("lua/utils/table_utils.lua")
local building = require("lua/buildings/building.lua")

class 'reflection_shield_generator' (building)

local master_list = {}

local short_interval = 0.1
local long_interval = 1.0

function reflection_shield_generator:__init()
	building.__init(self, self)
end

function reflection_shield_generator:OnInit()

	self.selected = {}
	self.radius = self.data:GetFloatOrDefault("range", 6)
	self.interval = self.data:GetFloatOrDefault("interval", 1)
	self.shieldBp = self.data:GetStringOrDefault("shield_bp", "buildings/defense/reflection_shield_generator/shield")

	self.shield_ent = EntityService:SpawnAndAttachEntity(self.shieldBp, self.entity)

	local shield_DB = EntityService:GetBlueprintDatabase(self.shield_ent)
	local decay_multiplier = 1.5
	if shield_DB then
		decay_multiplier = shield_DB:GetFloatOrDefault("decay_multiplier", 1.5)
	end

	local R_component = reflection_helper(EntityService:GetComponent(self.shield_ent, "RegenerationComponent"))
	self.regen_rate = R_component.regeneration
	self.decay_rate = -1 * self.regen_rate * decay_multiplier
	R_component.regeneration = 0
	self.regen_delay = R_component.regeneration_cooldown

	local RD_component = reflection_helper(EntityService:GetComponent(self.shield_ent, "ReflectDamageComponent"))
	self.reflector = {
		["melee_only"] = RD_component.melee_only,
		["reflect_type"] = RD_component.reflect_type,
		["damage_value"] = RD_component.damage_value,
		["damage_type"] = RD_component.damage_type}

	local RH_component = reflection_helper(EntityService:GetComponent(self.shield_ent, "ReflectHighlightComponent"))
	self.r_highlight = {
		["submesh_idx"] = RH_component.submesh_idx,
		["glow_factor"] = RH_component.glow_factor,
		["flash_time"] = RH_component.flash_time}

	self.sm_1 = self:CreateStateMachine()
	self.sm_1:AddState("running", {enter = "Start_Running", execute = "Loop_Running", exit = "End_Running", interval = short_interval})
	self.sm_1:AddState("draining", {execute = "Loop_Draining", interval = short_interval})
	self.sm_1:AddState("blown", {enter = "Start_Blown", execute = "Loop_Blown", interval = short_interval})
	
	self.sm_2 = self:CreateStateMachine()
	self.sm_2:AddState("searching", {execute = "Loop_Searching", interval = long_interval})
end

function reflection_shield_generator:OnBuildingEnd()
	ItemService:AddHealthLink(self.entity, self.shield_ent)
end

function reflection_shield_generator:OnActivate()
	self.sm_1:ChangeState("running")
	self:ChargeShield()
end

function reflection_shield_generator:OnDeactivate()
	self:DrainShield()
	self.sm_1:ChangeState("draining")
end

function reflection_shield_generator:OnSell()

	local state = self.sm_1:GetState("running")
	if (state ~= nil) then
		state:Exit()
	end
	
	ItemService:RemoveHealthLink(self.entity, self.shield_ent)
	master_list[self.entity] = nil
end

function reflection_shield_generator:OnDestroy()

	local state = self.sm_1:GetState("running")
	if (state ~= nil) then
		state:Exit()
	end

	ItemService:RemoveHealthLink(self.entity, self.shield_ent)
	master_list[self.entity] = nil
end

function reflection_shield_generator:Start_Running(state)
	self.sm_2:ChangeState("searching")
end

function reflection_shield_generator:Loop_Running(state)

	if not master_list[self.entity] then
		master_list[self.entity] = true 
		self:RebuildReflection()
	end

	if HealthService:GetHealth(self.shield_ent) < 0.1 then
		self.sm_1:ChangeState("blown")
	end
end

function reflection_shield_generator:End_Running(state)

	local searcher = self.sm_2:GetState("searching")
	if ( searcher ~= nil ) then
		searcher:Exit()
	end
end

function reflection_shield_generator:Loop_Searching(state)

	if (self.shield_ent == INVALID_ID or HealthService:GetHealth(self.shield_ent) == -1) then
		self.shield_ent = EntityService:SpawnAndAttachEntity(self.shieldBp, self.entity)
	end
	
	local objects = FindService:FindEntitiesByTypeInRadius(self.entity, "building", self.radius)

	for index, obj in ipairs(objects) do
		if (self.selected[obj] == nil and BuildingService:IsBuildingFinished(obj) and obj ~= self.entity) then
			ItemService:AddHealthLink(obj, self.shield_ent)
			self.selected[obj] = self:SetReflection(obj)
		end
	end

	for obj, status in pairs(self.selected) do
		if (IndexOf(objects, obj) == nil) then
			ItemService:RemoveHealthLink(obj, self.shield_ent)
			self.selected[obj] = nil
		end
	end
end

function reflection_shield_generator:Loop_Draining(state)

	if master_list[self.entity] == nil then master_list[self.entity] = true end
	
	if HealthService:GetHealth(self.shield_ent) > 0.1 then return end
	
	self:DeregisterAll()
	self:FlagAllForRebuild()
	state:Exit()
end

function reflection_shield_generator:Start_Blown(state)
	--ConsoleService:Write("Shield Blown!")
	for obj, status in pairs(self.selected) do
		if status == 1 then
			self:RemoveReflection(obj)
			self.selected[obj] = 2
		end
	end
	self:FlagAllForRebuild()
end

function reflection_shield_generator:Loop_Blown(state)

	if master_list[self.entity] == nil then master_list[self.entity] = true end
	
	if HealthService:GetHealth(self.shield_ent) < 0.1 then return end

	for obj, status in pairs(self.selected) do
		if status == 2 then
			self.selected[obj] = self:SetReflection(obj)
		end
	end
	self.sm_1:ChangeState("running")
end


function reflection_shield_generator:DeregisterAll()

	for obj, status in pairs(self.selected) do
		ItemService:RemoveHealthLink(obj, self.shield_ent)
		if status == 1 then self:RemoveReflection(obj) end 
		self.selected[obj] = nil --delete record
	end
	self:FlagAllForRebuild()
end

function reflection_shield_generator:RebuildReflection()
	for obj, status in pairs(self.selected) do
		if status == 0 then
			self.selected[obj] = self:SetReflection(obj)
		end
	end
end

function reflection_shield_generator:FlagAllForRebuild()
	for obj, status in pairs(master_list) do
		if obj ~= self.entity then
			master_list[obj] = false
		end
	end
end

function reflection_shield_generator:SetReflection(target)
	if not EntityService:IsAlive(target) then
		return nil
	elseif EntityService:HasComponent(target, "ReflectDamageComponent") then
		return 0
	else
		local RD_component = reflection_helper(EntityService:CreateComponent(target, "ReflectDamageComponent"))
		RD_component.melee_only = self.reflector["melee_only"]
		RD_component.reflect_type = self.reflector["reflect_type"]
		RD_component.damage_value = self.reflector["damage_value"]
		RD_component.damage_type = self.reflector["damage_type"]

		local RH_component = reflection_helper(EntityService:CreateComponent(target, "ReflectHighlightComponent"))
		RH_component.submesh_idx = self.r_highlight["submesh_idx"]
		RH_component.glow_factor = self.r_highlight["glow_factor"]
		RH_component.flash_time = self.r_highlight["flash_time"]

		return 1
	end
end

function reflection_shield_generator:RemoveReflection(target)
	EntityService:RemoveComponent(target, "ReflectDamageComponent")
	EntityService:RemoveComponent(target, "ReflectHighlightComponent")
end

function reflection_shield_generator:ChargeShield()
	local R_component = reflection_helper(EntityService:GetComponent(self.shield_ent, "RegenerationComponent"))
	R_component.regeneration = self.regen_rate
	R_component.regeneration_cooldown = self.regen_delay
end

function reflection_shield_generator:DrainShield()
	local R_component = reflection_helper(EntityService:GetComponent(self.shield_ent, "RegenerationComponent"))
	R_component.regeneration = self.decay_rate
	R_component.regeneration_cooldown = 0

	HealthService:SetHealth(self.shield_ent, HealthService:GetHealth(self.shield_ent) - 1);
end


return reflection_shield_generator