class 'logic_set_global_variable' ( LuaGraphNode )
require("lua/utils/table_utils.lua")

function logic_set_global_variable:__init()
    LuaGraphNode.__init(self, self)
end

function logic_set_global_variable:init()	
end

function logic_set_global_variable:Activated()

    local campaignData = CampaignService:GetCampaignData()

    local stringKeys = self.data:GetStringKeys()
    for key in Iter(stringKeys) do
        campaignData:SetString( key, self.data:GetString( key ) )
    end

    local floatKeys = self.data:GetFloatKeys()
    for key in Iter(floatKeys) do
        campaignData:SetFloat( key, self.data:GetFloat( key ) )
    end

	self:SetFinished()
end

return logic_set_global_variable