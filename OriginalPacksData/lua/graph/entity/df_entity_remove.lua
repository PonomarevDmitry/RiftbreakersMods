require("lua/utils/data_flow.lua")

class 'df_entity_remove' ( LuaGraphNode )

function df_entity_remove:__init()
    LuaGraphNode.__init(self, self)
end

local REMOVAL_HANDLER = {
    ["silent"] = function( entity )
        EntityService:RemoveEntity(entity)
    end,
    ["dissolve"] = function( entity, dissolve_duration )
        EntityService:DissolveEntity(entity, dissolve_duration)
    end,
    ["destroy"] = function( entity, _, destroy_pattern )
        EntityService:RequestDestroyPattern( entity, destroy_pattern, true )
    end
}

function df_entity_remove:Activated()
    local remove_type = self.data:GetString("remove_type")

    local dissolve_duration = self.data:GetFloat("dissolve_duration")
    local destroy_pattern = self.data:GetString("destroy_pattern")

    local entities = GetEntitiesFromString( self.data:GetString("in_entities") )

    local handler = REMOVAL_HANDLER[remove_type]
    if Assert( handler ~= nil, "ERROR: no handler for remove_type = '" .. tostring(remove_type) .. "'") then
        for entity in Iter(entities) do
            handler( entity, dissolve_duration, destroy_pattern)
        end
    end

    self:SetFinished();
end

return df_entity_remove