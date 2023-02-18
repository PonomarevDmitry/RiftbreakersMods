require("lua/utils/find_utils.lua")

class 'objective_cultivate_sapling' ( LuaGraphNode )

function objective_cultivate_sapling:__init()
    LuaGraphNode.__init(self, self)
end

function objective_cultivate_sapling:FillInitialParams()
    self.search_target = self.data:GetString("search_target");
    self.search_radius = self.data:GetFloat("search_radius")

    self.sapling_item = self.data:GetStringOrDefault("sapling_item", "")
end

function objective_cultivate_sapling:OnLoad()
    self:FillInitialParams()
end

function objective_cultivate_sapling:Activated()
    self:FillInitialParams()
end

function objective_cultivate_sapling:Update()
    local origin = FindService:FindEntityByName( self.search_target );
    if not EntityService:IsAlive( origin ) then
        return
    end

    local cultivators = BuildingService:GetFinishedBuildingByBp( origin, "buildings/resources/flora_cultivator", self.search_radius )
    if #cultivators <= 0 then
        return
    end

    if self.sapling_item ~= "" then
        for cultivator in Iter(cultivators) do
            EntityService:GetDatabase( cultivator ):SetString("sapling_item", self.sapling_item )

            local params = { sapling_item = self.sapling_item }
            QueueEvent( "LuaGlobalEvent", self.entity, "CultivateSapling", params )
        end
    end

    self:SetFinished();
end

return objective_cultivate_sapling