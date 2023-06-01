class 'objective_if_status' ( LuaGraphNodeSelector )
require("lua/utils/table_utils.lua")
require("lua/utils/enumerables.lua")

function objective_if_status:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function objective_if_status:init()
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "update", { from="*", execute="OnUpdate", interval=1 } );
	self.quests = self.data:GetStringKeys()
	self.localObjective = self.data:GetIntOrDefault("is_objective_local", 1)
end

function objective_if_status:Activated()
	self.fsm:ChangeState( "update" )
end

function objective_if_status:OnUpdate()
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
		self:SetFinished( "true")
    else
        self:SetFinished("false")
	end
end

return objective_if_status