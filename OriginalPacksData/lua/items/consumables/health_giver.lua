class 'health_giver' ( LuaEntityObject )

function health_giver:__init()
	LuaEntityObject.__init(self, self)
end

function health_giver:init()
	self.toHeal = EntityService:GetParent( self.entity )
	self.amount   = self.data:GetFloat( "amount" )
	self.time   = self.data:GetFloat( "time" )
	self.giverMachine = self:CreateStateMachine()
	self.giverMachine:AddState( "work", {enter="OnEnterWork", exit="OnExitWork" } )
	self.soundFSM:ChangeState("work")
end

function health_giver:OnEnterWork( state )
	ItemService:ChangeRegeneration( self.toHeal, self.amount / self.time )
	state:SetDurationLimit( self.time )
end

function health_giver:OnExitWork( state )
	ItemService:ChangeRegeneration(self.toHeal, -(self.amount / self.time) )
	EntityService:RemoveEntity( self.entity ) 
end

return health_giver
 