require("lua/utils/table_utils.lua")

class 'anoryxian_firewall' ( LuaEntityObject )

function anoryxian_firewall:__init()
	LuaEntityObject.__init(self, self)
end

function anoryxian_firewall:init()
	self:RegisterHandler( self.entity, "EnteredTriggerEvent",  "OnEnteredTriggerEvent" )
	self:RegisterHandler( self.entity, "LeftTriggerEvent", 	 "OnLeftTriggerEvent" )

	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "logic", { execute="OnExecuteLogic" } )
	self.fsm:ChangeState( "logic" )

	self.damageDealTo  = {}

	self.dealDamage = self.data:GetFloatOrDefault( "damage", 10.0 )
	self.owner = tonumber( self.data:GetStringOrDefault( "owner", "0" ) )
end

function anoryxian_firewall:OnEnteredTriggerEvent( evt )
	
	local entity = evt:GetOtherEntity()
	local groupId = EntityService:GetPhysicsGroupId( entity )
	if ( ( groupId == "world") or ( groupId == "world_blocker") or ( groupId == "destructible" ) ) then
		EntityService:RemoveEntity( self.entity )
	end

	if ( self.owner ~= entity  ) then
		table.insert( self.damageDealTo, entity )
	end
end

function anoryxian_firewall:OnLeftTriggerEvent( evt )
	Remove( self.damageDealTo, evt:GetOtherEntity() )
end

function anoryxian_firewall:OnExecuteLogic( state, dt )

	for i = 1, #self.damageDealTo, 1 do  
		QueueEvent( "DamageWithOwnerRequest", self.damageDealTo[i], self.dealDamage  * dt, "energy", 1, 0, self.entity, self.entity )
	end

end

return anoryxian_firewall
