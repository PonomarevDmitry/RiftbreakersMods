class 'objective_wait_on_status' ( LuaGraphNode )
require("lua/utils/table_utils.lua")
require("lua/utils/enumerables.lua")

function objective_wait_on_status:__init()
    LuaGraphNode.__init(self, self)
end

function objective_wait_on_status:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="OnUpdate", interval=1 } );
	self.quests = self.data:GetStringKeys()
	self.localObjective = self.data:GetIntOrDefault("is_objective_local", 1)
end

function objective_wait_on_status:Activated()
	self.fsm:ChangeState( "update" )
end

function objective_wait_on_status:OnUpdate()
	local allFinished = true
	for quest in Iter(self.quests)
	do
		local questName = quest
		if ( self.localObjective == 1 ) then
			 questName = self.parent:CreateGraphUniqueString( quest )
		end
		
		local questStatus = self.data:GetString( quest )

		if ( ObjectiveService:GetObjectiveStatus( ObjectiveService:GetObjectiveIdFromObjectiveUniqueName( questName ) ) ~= StringToObjectiveStatus(questStatus) ) then
			allFinished = false		
			break;
		end
	end
	
	if ( allFinished == true ) then
		self:SetFinished()
	end
end

return objective_wait_on_status