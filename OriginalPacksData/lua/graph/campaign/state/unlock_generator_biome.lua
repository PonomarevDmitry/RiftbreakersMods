class 'unlock_generator_biome' ( LuaGraphNode )

function unlock_generator_biome:__init()
	LuaGraphNode.__init(self,self)
end

function unlock_generator_biome:init()		
end

function unlock_generator_biome:Activated()							
	local name = self.data:GetString("biome_name")	
	CampaignService:UnlockBiome( name)
	self:SetFinished()	
end

return unlock_generator_biome