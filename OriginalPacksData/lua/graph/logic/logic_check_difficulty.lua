class 'logic_check_difficulty' ( LuaGraphNodeSelector )

function logic_check_difficulty:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_check_difficulty:init()
end

function logic_check_difficulty:Activated()
	
	local checkDifficulty = self.data:GetString( "difficulty" )

	local currentDifficulty = DifficultyService:GetWaveStrength()

	if ( checkDifficulty == currentDifficulty ) then
		self:SetFinished( "true" )
	else
		self:SetFinished( "false" )
	end	
end

return logic_check_difficulty