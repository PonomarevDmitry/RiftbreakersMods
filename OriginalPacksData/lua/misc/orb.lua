require("lua/units/units_utils.lua")

class 'orb' ( LuaEntityObject )

function orb:__init()
	LuaEntityObject.__init(self, self)
end

function orb:init()
	--EntityService:SetScale( self.entity, 0.2, 0.2, 0.2 ) -- remove this when the appropriate mesh is ready

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "rotation", { execute="OnRotationExecute" } )
	self.fsm:ChangeState( "rotation" )
end

function orb:OnRotationExecute( state, dt )
	EntityService:Rotate( self.entity, 0.0, 1.0, 0.0, 7 )
end


return orb
