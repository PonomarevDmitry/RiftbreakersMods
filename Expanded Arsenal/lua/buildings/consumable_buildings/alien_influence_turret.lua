local tower = require("lua/buildings/defense/tower.lua")

class 'alien_influence_turret' ( tower )

function alien_influence_turret:__init()
	tower.__init(self,self)
end

function alien_influence_turret:OnInit()
	EntityService:SetScale( self.entity, 0.65,0.65,0.65 )
	self:RegisterHandler( self.entity, "SpikeAmmoFiredEvent",  "OnSpikeAmmoFiredEvent" )
	
	self.fsm = self:CreateStateMachine()
	self.fsm:AddState( "working", {execute="OnWorkInProgress"} )
end

function alien_influence_turret:OnSpikeAmmoFiredEvent( evt )
	AnimationService:StartAnim( self.entity, "working", false )
end

function alien_influence_turret:OnWorkInProgress( state )

end

function alien_influence_turret:OnActivate()
	self.fsm:ChangeState("working")
end

function alien_influence_turret:OnDeactivate()
	local state = self.fsm:GetState("working")
	if ( state ~= nil ) then
		state:Exit()
	end	 
end

return alien_influence_turret
