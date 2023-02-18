class 'logic_if_difficulty' ( LuaGraphNodeSelector )

function logic_if_difficulty:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_difficulty:init()
end

function logic_if_difficulty:Activated()	

	local currentDifficulty = DifficultyService:GetCurrentDifficultyName()

	self:SetFinished( currentDifficulty )
	
end

return logic_if_difficulty