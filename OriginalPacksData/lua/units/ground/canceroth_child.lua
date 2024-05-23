require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'canceroth_child' ( base_unit )

function canceroth_child:__init()
	base_unit.__init(self, self)
end

function canceroth_child:OnInit()
	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 4

	local speedMin = self.data:GetFloatOrDefault( "min_idle_speed", 0.9 )
	local speedMax = self.data:GetFloatOrDefault( "max_idle_speed", 1.1 )
	local speed = speedMin + math.random() * ( speedMax - speedMin )
	self.data:SetFloat( "idle_speed", speed );

	self.parentCheckFSM = self:CreateStateMachine()
	self.parentCheckFSM:AddState( "parent_check", { execute="OnExecuteParentCheck", interval=0.5 } )
	self.parentCheckFSM:ChangeState( "parent_check" )  

end

function canceroth_child:OnExecuteParentCheck( state, dt )
	
	local parent = UnitService:GetNavMeshMoveToTarget( self.entity )

	if ( EntityService:IsAlive( parent ) == false ) then
		EntityService:RequestDestroyPattern( self.entity, "wreck" )
	end

end

return canceroth_child
