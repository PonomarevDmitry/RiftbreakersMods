class 'mission_change_creature_difficulty' ( LuaGraphNode )

function mission_change_creature_difficulty:__init()
    LuaGraphNode.__init(self, self)
end

function mission_change_creature_difficulty:init()
end

function mission_change_creature_difficulty:Activated()
	local mode = self.data:GetString("mode")
	local value = self.data:GetFloat("value")
	if mode == "set" then
		CampaignService:SetCreaturesBaseDifficulty( value )
	else
		CampaignService:IncreaseCreaturesBaseDifficulty( value )
	end

    self:SetFinished()
end

return mission_change_creature_difficulty