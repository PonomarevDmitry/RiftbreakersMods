class 'logic_if_difficulty_wave' ( LuaGraphNodeSelector )

function logic_if_difficulty_wave:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_difficulty_wave:init()
end

function logic_if_difficulty_wave:Activated()	

	local currentDifficulty = DifficultyService:GetWaveStrength()

	self:SetFinished( currentDifficulty )
	
end

return logic_if_difficulty_wave