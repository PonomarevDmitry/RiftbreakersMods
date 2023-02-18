local item = require("lua/items/item.lua")

class 'dodge_roll' ( item )

function dodge_roll:__init()
	item.__init(self,self)
end

function dodge_roll:OnInit()
	self.duration = self.data:GetFloatOrDefault("time", 10 )
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "rolling", { from="*", enter="OnRollEnter", exit="OnRollExit"} )

	self.rollSpeed = self.data:GetFloatOrDefault("roll_speed", 2.0 )
end

function dodge_roll:OnEquipped()
	self:RegisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	local db = EntityService:GetDatabase( self.owner );
	db:SetFloat( "roll_speed", self.rollSpeed);
end

function dodge_roll:OnActivate()
	EntityService:Dash( self.owner, self.item );

end

function dodge_roll:OnUnequipped()
	self.machine:Deactivate()
	self:UnregisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
end

function dodge_roll:OnRollEnter( state )
	EntityService:DisableCollisions(self.owner);
	HealthService:SetImmortality( self.owner, true );
	EntityService:ChangeCharacterControllerGroupId( self.owner, "debris");
end

function dodge_roll:OnRollExit()
	EntityService:EnableCollisions(self.owner);
	HealthService:SetImmortality( self.owner, false );
	EntityService:ChangeCharacterControllerGroupId( self.owner, "character");

end

function dodge_roll:OnAnimationMarkerReached(evt)
	if ( evt:GetMarkerName() == "roll_start" ) then
		self.machine:ChangeState("rolling")
	elseif ( evt:GetMarkerName() == "roll_end" ) then
		self.machine:Deactivate()
	end
end

return dodge_roll
