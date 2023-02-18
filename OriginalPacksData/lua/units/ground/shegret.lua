require("lua/utils/table_utils.lua")

local base_unit = require("lua/units/base_unit.lua")
class 'shegret' ( base_unit )

function shegret:__init()
	base_unit.__init(self, self)
end

function shegret:OnInit()
	self:RegisterHandler( self.entity, "StartLeechEvent",  "OnStartLeechEvent" )
	self:RegisterHandler( self.entity, "EndLeechEvent",  "OnEndLeechEvent" )

	self.wreck_type = "wreck_big"
	self.wreckMinSpeed = 4

	self.currentLeechTarget = INVALID_ID
	self.leechDmg = 0

	self.leechFSM = self:CreateStateMachine()
	self.leechFSM:AddState( "start_leech", { execute="OnLeechExecute" } )
	self.leechFSM:AddState( "stop_leech", {  } )

	self.data:SetInt( "skip_dig_up", 0 )
	UnitService:SetStateMachineParam( self.entity, "move_target_valid", 0 )

	EntityService:SetVisible( self.entity, false );

end

function shegret:OnLeechExecute( state, dt )
	if ( self.currentLeechTarget ~= INVALID_ID ) then
		QueueEvent( "DamageRequest", self.currentLeechTarget, self.leechDmg * dt, "energy", 1, 0 )
	end
end

function shegret:OnStartLeechEvent( evt )
	local target = UnitService:GetCurrentTarget( evt:GetEntity(), evt:GetTargetTag() )

	if ( ( target ~= self.currentLeechTarget ) and ( self.currentLeechTarget ~= INVALID_ID ) ) then

		if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == true ) then
			EffectService:DestroyEffectsByGroup( self.currentLeechTarget, "leech" )
		end
	end

	self.currentLeechTarget = target
	self.leechDmg = evt:GetLeechDamage()

	if ( self.currentLeechTarget ~= INVALID_ID ) then
		UnitService:AnimBoneForwardToTargetEntity( self.entity, self.currentLeechTarget, "attack_pos", "range_length_hit_vector", 1.5, 2.0 )
		if ( EffectService:HasEffectByGroup( self.entity, "energy_leech" ) == false ) then
			EffectService:AttachEffects( self.entity, "energy_leech" )
		end
	end
end

function shegret:OnEndLeechEvent( evt )
	EffectService:DestroyEffectsByGroup( self.entity, "energy_leech" )
	if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == true ) then
		EffectService:DestroyEffectsByGroup( self.currentLeechTarget, "leech" )
	end

	self.leechFSM:ChangeState( "stop_leech" )
end

function shegret:OnAnimationMarkerReached( evt )
	
	local markerName = evt:GetMarkerName() 
	if ( markerName == "dig_up" ) then
		EntityService:SetVisible( self.entity, true );
	end

	if ( markerName == "start_leech"  ) then
		if ( self.currentLeechTarget ~= INVALID_ID ) then
			if ( EffectService:HasEffectByGroup( self.currentLeechTarget, "leech" ) == false ) then
				EffectService:AttachEffects( self.currentLeechTarget, "leech" )
			end
		end

		self.leechFSM:ChangeState( "start_leech" )
		return false;
	end

	return true;
end

return shegret
