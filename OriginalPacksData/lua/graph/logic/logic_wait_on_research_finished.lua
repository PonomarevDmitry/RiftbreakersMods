class 'logic_wait_on_research_finished' ( LuaGraphNode )
require("lua/utils/table_utils.lua")
require("lua/utils/enumerables.lua")

function logic_wait_on_research_finished:__init()
    LuaGraphNode.__init(self, self)
end

function logic_wait_on_research_finished:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="OnUpdate", interval=1 } );
	self.objective = self.data:GetString( "research_id" )
end

function logic_wait_on_research_finished:Activated()
	self.fsm:ChangeState( "update" )
end

function logic_wait_on_research_finished:OnUpdate()
	local researchId = self.data:GetString("research_id")    
	local finished = PlayerService:IsResearchUnlocked( researchId )

	if ( finished ) then
		self:SetFinished()
	end
end

return logic_wait_on_research_finished