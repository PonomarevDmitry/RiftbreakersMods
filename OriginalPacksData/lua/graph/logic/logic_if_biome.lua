class 'logic_if_biome' ( LuaGraphNodeSelector )

function logic_if_biome:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_if_biome:init()
end

function logic_if_biome:Activated()
	
	local checkBiome = self.data:GetString( "biome" )

	local currentBiome = MissionService:GetCurrentBiomeName()

	if ( checkBiome == currentBiome ) then
		self:SetFinished( "true" )
	else
		self:SetFinished( "false" )
	end	
end

return logic_if_biome