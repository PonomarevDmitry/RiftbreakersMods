local wall_gate = require("lua/buildings/defense/wall_gate.lua")

class 'advanced_energy_walls_gate' ( wall_gate )

function advanced_energy_walls_gate:__init()
	building_base.__init(self,self)
end

function advanced_energy_walls_gate:OnInit()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent",  "OnLeftTriggerEvent" )
	self.down = false

	self:FindCollisionChild()
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState("Working", {execute = "OnWorking", interval = 0.1})
end


function advanced_energy_walls_gate:OnBuildingEnd()
	
	self:MoveUp()
	
	local R_component = reflection_helper(EntityService:GetComponent(self.entity, "RegenerationComponent")) -- check regeneration params
	self.regen_rate = R_component.regeneration

	local RD_component = reflection_helper(EntityService:GetComponent(self.entity, "ReflectDamageComponent"))
	self.reflector = {
		["melee_only"] = RD_component.melee_only,
		["reflect_type"] = RD_component.reflect_type,
		["damage_value"] = RD_component.damage_value,
		["damage_type"] = RD_component.damage_type}

	local RH_component = reflection_helper(EntityService:GetComponent(self.entity, "ReflectHighlightComponent"))
	self.r_highlight = {
		["submesh_idx"] = RH_component.submesh_idx,
		["glow_factor"] = RH_component.glow_factor,
		["flash_time"] = RH_component.flash_time}	
end

function advanced_energy_walls_gate:OnActivate()
	self.active = true
	self.fsm:ChangeState("Working")
end

function advanced_energy_walls_gate:OnDeactivate()

	self.active = false
	
	self:DisableReflection()
	
	local state = self.fsm:GetState("Working")
	if (state ~= nil) then
		state:Exit()
	end
end

function advanced_energy_walls_gate:OnWorking( state )
	if self.active then
		self:EnableReflection()
	else
		return
	end
end

function advanced_energy_walls_gate:EnableReflection()
	if not EntityService:IsAlive(self.entity) then
		return nil
	elseif EntityService:HasComponent(self.entity, "ReflectDamageComponent") then
		return 0
	else
		
		local R_component = reflection_helper(EntityService:GetComponent(self.entity, "RegenerationComponent"))
		R_component.regeneration = self.regen_rate
		
		local RD_component = reflection_helper(EntityService:CreateComponent(self.entity, "ReflectDamageComponent"))
		RD_component.melee_only = self.reflector["melee_only"]
		RD_component.reflect_type = self.reflector["reflect_type"]
		RD_component.damage_value = self.reflector["damage_value"]
		RD_component.damage_type = self.reflector["damage_type"]

		local RH_component = reflection_helper(EntityService:CreateComponent(self.entity, "ReflectHighlightComponent"))
		RH_component.submesh_idx = self.r_highlight["submesh_idx"]
		RH_component.glow_factor = self.r_highlight["glow_factor"]
		RH_component.flash_time = self.r_highlight["flash_time"]

		return 1
	end
end

function advanced_energy_walls_gate:DisableReflection()

	local R_component = reflection_helper(EntityService:GetComponent(self.entity, "RegenerationComponent"))
	R_component.regeneration = 0
	
	EntityService:RemoveComponent(self.entity, "ReflectDamageComponent")
	EntityService:RemoveComponent(self.entity, "ReflectHighlightComponent")
end


function advanced_energy_walls_gate:OnDestroy()
	return true
end

return advanced_energy_walls_gate
