class 'df_entity_array_merge' ( LuaGraphNode )

function df_entity_array_merge:__init()
    LuaGraphNode.__init(self, self)
end

function df_entity_array_merge:Activated()
    local entities_1 = self.data:GetString("in_entities_1")
    local entities_2 = self.data:GetStringOrDefault("in_entities_2", "")

    local merged_entities = entities_1;
    if entities_1 ~= "" and entities_2 ~= "" then
        merged_entities = merged_entities .. ","
    end

    merged_entities = merged_entities .. entities_2

    self.data:SetString("out_entities", merged_entities)

    self:SetFinished()
end

return df_entity_array_merge