class 'fertilizer' ( LuaEntityObject )
require("lua/utils/reflection.lua")

function fertilizer:__init()
	LuaEntityObject.__init(self,self)
end

function fertilizer:init()
	self.radius = self.data:GetFloatOrDefault("radius", 0.0)

	local interval = self.data:GetFloatOrDefault("interval", 5.0)
	self.fsm = self:CreateStateMachine();
	self.fsm:AddState("fertilize_vegetation", { execute = "OnFertilizeVegetationExecute", interval = interval })
	self.fsm:ChangeState("fertilize_vegetation")
end

function fertilizer:OnFertilizeVegetationExecute()
	self.predicate = self.predicate or {
		signature = "VegetationLifecycleEnablerComponent,VegetationLifecycleComponent"
	}

	local effect_blueprint = self.data:GetStringOrDefault("fertilize_effect", "")

	local entities = FindService:FindEntitiesByPredicateInRadius(self.entity, self.radius, self.predicate)
	for entity in Iter(entities) do
		EntityService:RemoveComponent(entity, "VegetationLifecycleComponent")
		EntityService:CreateComponent(entity, "VegetationLifecycleComponent") -- create new component that will trigger re-growth on next update

		if effect_blueprint ~= "" then
			EffectService:SpawnEffect( entity, effect_blueprint )
		end
	end
end

return fertilizer
 