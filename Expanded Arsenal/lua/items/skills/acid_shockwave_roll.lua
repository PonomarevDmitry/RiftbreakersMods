local item = require("lua/items/item.lua")

class 'acid_shockwave_roll' ( item )

function acid_shockwave_roll:__init()
	item.__init(self,self)
end

function acid_shockwave_roll:FillInitialParams()
	local database = EntityService:GetBlueprintDatabase( self.entity ) or self.data;
    self.bp = database:GetString( "bp" )
	self.att = database:GetString( "att" )
	self.checkEmptySpot = database:GetIntOrDefault( "check_empty_spot", 0 )
end

function acid_shockwave_roll:OnLoad()
	item.OnLoad(self)
	self:FillInitialParams()
end

function acid_shockwave_roll:OnInit()
	self.duration = self.data:GetFloatOrDefault("time", 10 )
	self.machine = self:CreateStateMachine()
	self.machine:AddState( "rolling", { from="*", enter="OnRollEnter", exit="OnRollExit"} )

	self.rollSpeed = self.data:GetFloatOrDefault("roll_speed", 2.0 )
	self:FillInitialParams()
end

function acid_shockwave_roll:OnEquipped()
	self:RegisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
	local db = EntityService:GetDatabase( self.owner );
	db:SetFloat( "roll_speed", self.rollSpeed);
end

function acid_shockwave_roll:OnActivate()
	EntityService:Dash( self.owner, self.item );
	
	local spawned = EntityService:SpawnEntity( self.bp, self.owner, self.att, EntityService:GetTeam( self.owner ))
	EntityService:SetGraphicsUniform( spawned, "cDissolveAmount", 1 )
	ItemService:SetItemCreator( spawned, self.bp)
	QueueEvent( "FadeEntityInRequest", spawned, 0.5 );

end

function acid_shockwave_roll:OnUnequipped()
	self.machine:Deactivate()
	self:UnregisterHandler( self.owner, "AnimationMarkerReached", "OnAnimationMarkerReached" )
end

function acid_shockwave_roll:OnRollEnter( state )
	EntityService:DisableCollisions(self.owner);
	HealthService:SetImmortality( self.owner, true );
	EntityService:ChangeCharacterControllerGroupId( self.owner, "debris");
end

function acid_shockwave_roll:OnRollExit()
	EntityService:EnableCollisions(self.owner);
	HealthService:SetImmortality( self.owner, false );
	EntityService:ChangeCharacterControllerGroupId( self.owner, "character");

end

function acid_shockwave_roll:OnAnimationMarkerReached(evt)
	if ( evt:GetMarkerName() == "roll_start" ) then
		self.machine:ChangeState("rolling")
	elseif ( evt:GetMarkerName() == "roll_end" ) then
		self.machine:Deactivate()
	end
end

function acid_shockwave_roll:CanActivate()
	if ( self.checkEmptySpot == 0 ) then
		return true
	end

    local pos = FindService:FindEmptySpotInRadius( self.owner, 2.0, "", "")
    return pos.first
end


return acid_shockwave_roll
