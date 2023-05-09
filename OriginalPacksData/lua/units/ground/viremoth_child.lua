require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'viremoth_child' ( base_unit )

function viremoth_child:__init()
	base_unit.__init(self, self)
end

function viremoth_child:OnInit()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent", 	 "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )

	self.wreck_type = "wreck_small"
	self.wreckMinSpeed = 4

	self.isTrigger = false;

	self.inTrigger  = {}

end

function viremoth_child:OnEnteredTriggerEvent( evt )
	local params = { target = tostring( evt:GetOtherEntity() )  }
	QueueEvent( "LuaGlobalEvent", UnitService:GetNavMeshMoveToTarget( self.entity ), "ChildDealEvent", params )
	table.insert( self.inTrigger, evt:GetOtherEntity() )
	self.isTrigger = true
end

function viremoth_child:OnLeftTriggerEvent( evt )
	local params = { target = tostring( evt:GetOtherEntity() )  }
	QueueEvent( "LuaGlobalEvent", UnitService:GetNavMeshMoveToTarget( self.entity ), "ChildReleaseEvent", params )
	Remove( self.inTrigger, evt:GetOtherEntity() )
	self.isTrigger = false
end

function viremoth_child:_OnDestroyRequest( state )
	if ( self.isTrigger == true ) then
		for i = 1, #self.inTrigger, 1 do 
			local params = { target = tostring( self.inTrigger[i] ) }
			QueueEvent( "LuaGlobalEvent", UnitService:GetNavMeshMoveToTarget( self.entity ), "ChildReleaseEvent", params )
		end		
	end

	EntityService:RemoveEntity( self.entity )	
end

return viremoth_child
