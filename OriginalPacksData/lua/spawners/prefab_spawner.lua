class 'prefab_spawner' ( LuaEntityObject )

function prefab_spawner:__init()
	LuaEntityObject.__init(self,self)
end

function prefab_spawner:init()
    self.fsm = self:CreateStateMachine()
    self.fsm:AddState("spawn", { enter="OnSpawnEnter", exit="OnSpawnExit" })

    self.fsm:ChangeState("spawn")
end

function prefab_spawner:OnSpawnEnter(state)
    local duration = math.max( 0.1, self.data:GetFloatOrDefault("spawn_delay", 0.0) )
    state:SetDurationLimit(duration )
end

function prefab_spawner:OnSpawnExit()
    local radius = self.data:GetFloatOrDefault("radius", 10)

    local prefab = self.data:GetStringOrDefault("prefab", "")
    local prefab_variant = self.data:GetStringOrDefault("variant", "")

    local randomize_orientation = self.data:GetIntOrDefault("randomize_orientation", 0) == 1
    local randomize_position = self.data:GetIntOrDefault("randomize_position", 0) == 1

    EntityService:SpawnPrefabEntitiesInRadius( self.entity, prefab, prefab_variant, randomize_position, randomize_orientation, radius )
end

return prefab_spawner