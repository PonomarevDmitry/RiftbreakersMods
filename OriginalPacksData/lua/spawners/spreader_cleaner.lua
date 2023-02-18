require ( "lua/utils/table_utils.lua" )
require ( "lua/utils/numeric_utils.lua" )
class 'spreader_cleaner' ( LuaEntityObject )

function spreader_cleaner:__init()
	LuaEntityObject.__init(self,self)
end

function spreader_cleaner:init()	
	self.collapse_interval = self.data:GetFloatOrDefault( "collapse_interval", 1 );

	self.machine = self:CreateStateMachine();
	self.machine:AddState( "collapse", { execute="OnCollapseExecute", interval=self.collapse_interval  } );
	self.machine:ChangeState("collapse")
	
	self.branches = {}
	local keys = self.data:GetIntKeys()

	for key in Iter(keys) do
		if ( string.find( key, "branch_")) then
			Insert(self.branches, self.data:GetInt(key) )
		end
	end
end

function spreader_cleaner:OnCollapseExecute( state )
	for i=#self.branches,1,-1 do
		
		local toDestroy = self.branches[ i ];
		Remove(self.branches, toDestroy);

		if ( EntityService:IsAlive( toDestroy ) and HealthService:IsAlive( toDestroy )  ) then
			EntityService:DissolveEntity( toDestroy, 1 )
			break
		end
	end

	if ( #self.branches == 0 ) then
		EntityService:RemoveEntity( self.entity  )
		state:Exit();
		return;
	end
end

return spreader_cleaner