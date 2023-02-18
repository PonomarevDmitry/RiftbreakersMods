local mission_base = require("lua/missions/mission_base.lua")
class 'survival_base' ( mission_base )
require("lua/utils/reflection.lua")

function survival_base:__init()
    mission_base.__init(self,self)
end


function survival_base:AddSaplingItemsToPlayerInventory()
    if CampaignService:GetCurrentCampaignType() ~= "survival" then
        return
    end
    PlayerService:AddItemsByTypeToInventory(0, "saplings")
end

function survival_base:SetupInitialTime()
    local waveStrength = DifficultyService:GetWaveStrength()
    if ( waveStrength == "easy") then
        return
    end

    local biomName = MissionService:GetCurrentBiomeName()

    if ( waveStrength == "normal" and biomName == "jungle") then
        return
    end

    local time = RandInt(0,24 )
    EnvironmentService:SetTimeOfDayHour(time)
end

function survival_base:Update()
    if not self.saplings_created then
        self:AddSaplingItemsToPlayerInventory();
        self.saplings_created = true
    end

    if (not  self.time_initialized ) then
        local time_of_day_system_data_component = EntityService:GetSingletonComponent("TimeOfDaySystemDataComponent")
        if time_of_day_system_data_component and reflection_helper(time_of_day_system_data_component).initialized then

            self:SetupInitialTime();
            self.time_initialized = true
        end
    end
end

function survival_base:OnLoad()
    self.time_initialized = true
end

return survival_base
