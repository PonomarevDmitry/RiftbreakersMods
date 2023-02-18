require ( "lua/utils/enumerables.lua" )
class 'mission_planetary_jump' ( LuaGraphNode )

function mission_planetary_jump:__init()
	LuaGraphNode.__init(self,self)
end

function mission_planetary_jump:init()

end

function mission_planetary_jump:Activated()   
	local state = self.data:GetStringOrDefault("state", "Enable" )	
    CampaignService:OperatePlanetaryJump( state == "Enable" )
	self:SetFinished();
end


return mission_planetary_jump