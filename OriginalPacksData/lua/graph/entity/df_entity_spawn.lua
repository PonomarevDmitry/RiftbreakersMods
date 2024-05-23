class 'df_entity_spawn' ( LuaGraphNode )

function df_entity_spawn:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_spawn:Activated()
    local spawn_type = self.data:GetString("spawn_type")
    local spawn_type_value = self.data:GetString("spawn_type_value")

    if self.data:HasString("in_objective_id") then
        local objective_id = tonumber( self.data:GetString("in_objective_id") )
        spawn_type_value = ObjectiveService:GetObjectiveMarkerBlueprint( objective_id )
    end

    local set_entity_name = self.data:GetString("set_entity_name")
    local is_set_entity_name_local = self.data:GetInt("is_set_entity_name_global") == 1
    if is_set_entity_name_local == 0 and set_entity_name ~= "" then
        set_entity_name = self.parent:CreateGraphUniqueString( set_entity_name )
    end

    local set_entity_group = self.data:GetString("set_entity_group")
    local set_entity_team = self.data:GetString("set_entity_team")

    local attach_entity_to_target = self.data:GetInt("attach_entity_to_target") == 1
    local target_attachment_name = self.data:GetString("target_attachment_name")

    local spawned_entities = {}

    local target_entities = GetEntitiesFromString( self.data:GetString("in_entities") )
    for target_entity in Iter(target_entities) do
        local spawned_entity = INVALID_ID
        if attach_entity_to_target then
            spawned_entity = EntityService:SpawnAndAttachEntity( spawn_type_value, target_entity, target_attachment_name, "" )
        else
            spawned_entity = EntityService:SpawnEntity( spawn_type_value, target_entity, target_attachment_name, "" )
        end
    
        if set_entity_name ~= "" then
            EntityService:SetName( spawned_entity, set_entity_name )
        end

        if set_entity_group ~= "" then
            EntityService:SetGroup( spawned_entity, set_entity_group )
        end

        if set_entity_team ~= "" then
            EntityService:SetTeam( spawned_entity, set_entity_team )
        end

        table.insert(spawned_entities, spawned_entity)
    end

    local out_entities = GetEntitiesAsString(spawned_entities)
    self.data:SetString("out_entities", out_entities)

    self:SetFinished()
end

return df_entity_spawn